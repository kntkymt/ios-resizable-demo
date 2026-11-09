import AVFoundation
import Combine
import ImageIO
import Observation
import UIKit

// CameraScreen の裏側。AVCaptureDevice の探索・観測、AVCaptureSession の接続、写真撮影をまとめる。
// プロジェクトは SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor なので、このクラスは MainActor 上で動く。
// AVCaptureSession.startRunning / stopRunning はブロッキングなので CaptureEngine 側の直列キューに逃がしている。

@Observable
final class CameraController {
    // MARK: - Discovery

    var position: PositionOption = .unspecified
    var deviceTypes: Set<CameraDeviceTypeOption> = [.builtInWideAngleCamera]
    private(set) var discoveredDevices: [AVCaptureDevice] = []
    private(set) var discoverySummary = "(not run)"

    /// リストでタップして選んだデバイス。詳細表示・設定変更の対象。セッションに繋いだデバイスとは別に持つ。
    var selectedDevice: AVCaptureDevice? {
        didSet { observeSelectedDevice() }
    }
    private(set) var snapshot: DeviceSnapshot?

    // MARK: - Session

    private let engine = CaptureEngine()
    let previewLayer: AVCaptureVideoPreviewLayer
    private(set) var connectedDevice: AVCaptureDevice?
    private(set) var isSessionRunning = false
    private(set) var isBusy = false

    // MARK: - Rotation

    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    /// RotationCoordinator が報告する値。レイヤーがウィンドウに乗っていないと 0 になる。
    private(set) var previewRotationAngle: CGFloat = 0
    private(set) var captureRotationAngle: CGFloat = 0
    /// previewLayer.connection に実際にセットされている角度。接続前は nil。
    private(set) var previewConnectionRotationAngle: CGFloat?
    var previewRotation: RotationSource = .coordinator {
        didSet { applyPreviewRotation() }
    }
    var captureRotation: RotationSource = .coordinator

    // MARK: - Photo

    var capturedPhoto: CapturedPhoto?
    private(set) var isCapturing = false

    // MARK: - Misc

    private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    private(set) var logLines: [String] = []

    private var deviceObservers: [AnyCancellable] = []
    private var rotationObservers: [AnyCancellable] = []
    private var sessionObservers: [AnyCancellable] = []

    init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: engine.session)
        previewLayer.videoGravity = .resizeAspect

        sessionObservers = [
            engine.session.publisher(for: \.isRunning, options: [.initial, .new])
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isRunning in
                    self?.isSessionRunning = isRunning
                    self?.log("session.isRunning = \(isRunning)")
                    // 接続直後は connection がまだ無いことがあるので、走り出したタイミングでも角度を当て直す。
                    self?.applyPreviewRotation()
                },
        ]
    }

    // MARK: - Authorization

    func requestAccessIfNeeded() async {
        if authorizationStatus == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        log("authorization: \(authorizationStatus.title)")
    }

    // MARK: - Discovery

    func runDiscoverySession() {
        let types = CameraDeviceTypeOption.allCases.filter { deviceTypes.contains($0) }.map(\.deviceType)
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: position.value
        )
        discoveredDevices = session.devices
        discoverySummary = "\(session.devices.count) devices, \(session.supportedMultiCamDeviceSets.count) multiCam sets"
        log("DiscoverySession(\(types.map(\.shortName).joined(separator: ", ")), \(position.rawValue)) -> \(session.devices.count)")

        // 選択中のデバイスが結果から消えたら選択も解除する。
        if let selectedDevice, !discoveredDevices.contains(selectedDevice) {
            self.selectedDevice = nil
        }
    }

    // MARK: - Session

    func connect(_ device: AVCaptureDevice) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await engine.connect(deviceUniqueID: device.uniqueID)
                connectedDevice = device
                setUpRotationCoordinator(for: device)
                applyPreviewRotation()
                log("connected: \(device.localizedName)")
            } catch {
                log("connect failed: \(error.localizedDescription)")
            }
            isBusy = false
        }
    }

    func disconnect() {
        guard !isBusy else { return }
        isBusy = true
        Task {
            await engine.disconnect()
            connectedDevice = nil
            rotationCoordinator = nil
            rotationObservers.removeAll()
            previewRotationAngle = 0
            captureRotationAngle = 0
            previewConnectionRotationAngle = nil
            log("disconnected")
            isBusy = false
        }
    }

    // MARK: - Rotation

    private func setUpRotationCoordinator(for device: AVCaptureDevice) {
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        rotationObservers = [
            coordinator.publisher(for: \.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new])
                .receive(on: DispatchQueue.main)
                .sink { [weak self] angle in
                    self?.previewRotationAngle = angle
                    self?.log("coordinator preview angle = \(Int(angle))")
                    self?.applyPreviewRotation()
                },
            coordinator.publisher(for: \.videoRotationAngleForHorizonLevelCapture, options: [.initial, .new])
                .receive(on: DispatchQueue.main)
                .sink { [weak self] angle in
                    self?.captureRotationAngle = angle
                    self?.log("coordinator capture angle = \(Int(angle))")
                },
        ]
    }

    private func applyPreviewRotation() {
        guard let connection = previewLayer.connection else {
            previewConnectionRotationAngle = nil
            return
        }
        let angle = previewRotation.angle(coordinator: previewRotationAngle)
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        } else {
            log("preview angle \(Int(angle)) is not supported")
        }
        previewConnectionRotationAngle = connection.videoRotationAngle
    }

    // MARK: - Device configuration

    func setSwitchingBehavior(
        _ behavior: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior,
        conditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions
    ) {
        guard let device = selectedDevice else { return }
        // 非対応のデバイスに対して呼ぶと NSInvalidArgumentException で落ちる。
        guard device.primaryConstituentDeviceSwitchingBehavior != .unsupported else {
            log("switching behavior is unsupported on \(device.localizedName)")
            return
        }
        // conditions は behavior が .restricted のときにだけ指定できる (それ以外で非空だと例外)。
        let conditions = behavior == .restricted ? conditions : []
        do {
            try device.lockForConfiguration()
            device.setPrimaryConstituentDeviceSwitchingBehavior(behavior, restrictedSwitchingBehaviorConditions: conditions)
            device.unlockForConfiguration()
            log("set behavior = \(behavior.title), conditions = \(conditions.title)")
        } catch {
            log("lockForConfiguration failed: \(error.localizedDescription)")
        }
        refreshSnapshot()
    }

    @available(iOS 27.0, *)
    func lockSwitchingBehavior(to constituent: AVCaptureDevice) {
        guard let device = selectedDevice else { return }
        guard device.isPrimaryConstituentDeviceSwitchingBehaviorLockedWithDeviceSupported else {
            log("lock with device is unsupported on \(device.localizedName)")
            return
        }
        do {
            try device.lockForConfiguration()
            device.setPrimaryConstituentDeviceSwitchingBehaviorLockedWith(constituent)
            device.unlockForConfiguration()
            log("locked to \(constituent.localizedName)")
        } catch {
            log("lockForConfiguration failed: \(error.localizedDescription)")
        }
        refreshSnapshot()
    }

    func setZoom(_ factor: CGFloat) {
        guard let device = selectedDevice else { return }
        let clamped = min(max(factor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch {
            log("lockForConfiguration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Photo

    func capturePhoto() {
        guard !isCapturing, let connectedDevice else { return }
        let connection = engine.photoOutput.connection(with: .video)
        var requestedAngle: CGFloat?
        if let connection {
            let angle = captureRotation.angle(coordinator: captureRotationAngle)
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
                requestedAngle = angle
            } else {
                log("capture angle \(Int(angle)) is not supported")
            }
        }

        isCapturing = true
        Task {
            do {
                let photo = try await engine.capturePhoto(requestedRotationAngle: requestedAngle)
                capturedPhoto = photo
                log("captured: \(photo.photoDimensions) from \(photo.sourceDeviceType) (device: \(connectedDevice.localizedName))")
            } catch {
                log("capture failed: \(error.localizedDescription)")
            }
            isCapturing = false
        }
    }

    // MARK: - Observation

    private func observeSelectedDevice() {
        deviceObservers.removeAll()
        guard let device = selectedDevice else {
            snapshot = nil
            return
        }
        // 動的に変わる値だけ KVO で見て、変化があればスナップショットごと作り直す。
        let publishers: [AnyPublisher<Void, Never>] = [
            device.publisher(for: \.activePrimaryConstituent).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.activePrimaryConstituentDeviceSwitchingBehavior).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.activePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.videoZoomFactor).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.minAvailableVideoZoomFactor).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.maxAvailableVideoZoomFactor).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.isConnected).map { _ in }.eraseToAnyPublisher(),
            device.publisher(for: \.activeFormat).map { _ in }.eraseToAnyPublisher(),
        ]
        deviceObservers = [
            Publishers.MergeMany(publishers)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.refreshSnapshot()
                },
        ]
        refreshSnapshot()
    }

    private func refreshSnapshot() {
        snapshot = selectedDevice.map { DeviceSnapshot(device: $0) }
    }

    private func log(_ message: String) {
        let time = Date().formatted(date: .omitted, time: .standard)
        logLines.insert("\(time) \(message)", at: 0)
        if logLines.count > 30 {
            logLines.removeLast(logLines.count - 30)
        }
    }
}

// MARK: - Options

enum PositionOption: String, CaseIterable, Identifiable {
    case unspecified
    case back
    case front

    var id: String { rawValue }

    var value: AVCaptureDevice.Position {
        switch self {
        case .unspecified: .unspecified
        case .back: .back
        case .front: .front
        }
    }
}

/// DiscoverySession に渡せるカメラ系の DeviceType。
enum CameraDeviceTypeOption: String, CaseIterable, Identifiable {
    case builtInWideAngleCamera
    case builtInUltraWideCamera
    case builtInTelephotoCamera
    case builtInDualCamera
    case builtInDualWideCamera
    case builtInTripleCamera
    case builtInTrueDepthCamera
    case builtInLiDARDepthCamera
    case continuityCamera
    case external
    case builtInOuterUltraWideCamera
    case builtInInnerUltraWideCamera

    var id: String { rawValue }

    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .builtInWideAngleCamera: .builtInWideAngleCamera
        case .builtInUltraWideCamera: .builtInUltraWideCamera
        case .builtInTelephotoCamera: .builtInTelephotoCamera
        case .builtInDualCamera: .builtInDualCamera
        case .builtInDualWideCamera: .builtInDualWideCamera
        case .builtInTripleCamera: .builtInTripleCamera
        case .builtInTrueDepthCamera: .builtInTrueDepthCamera
        case .builtInLiDARDepthCamera: .builtInLiDARDepthCamera
        case .continuityCamera: .continuityCamera
        case .external: .external
        // iOS 27.1 SDK で追加された定数。27.0 SDK でもビルドできるように rawValue で参照する
        // (定数の文字列値はシンボル名と同じ)。未知の文字列を DiscoverySession に渡しても例外にはならず、単に無視される。
        case .builtInOuterUltraWideCamera, .builtInInnerUltraWideCamera:
            AVCaptureDevice.DeviceType(rawValue: "AVCaptureDeviceType" + rawValue.prefix(1).uppercased() + rawValue.dropFirst())
        }
    }

    var note: String? {
        switch self {
        case .builtInOuterUltraWideCamera, .builtInInnerUltraWideCamera: "iOS 27.1+"
        case .continuityCamera, .external: "iOS 17+"
        default: nil
        }
    }
}

/// プレビュー / 撮影に適用する videoRotationAngle をどこから取るか。
enum RotationSource: String, CaseIterable, Identifiable {
    case coordinator
    case angle0 = "0"
    case angle90 = "90"
    case angle180 = "180"
    case angle270 = "270"

    var id: String { rawValue }

    func angle(coordinator value: CGFloat) -> CGFloat {
        switch self {
        case .coordinator: value
        case .angle0: 0
        case .angle90: 90
        case .angle180: 180
        case .angle270: 270
        }
    }
}

// MARK: - Snapshot

/// 画面に出す AVCaptureDevice のプロパティを、ある時点で読み取ってまとめたもの。
/// AVCaptureDevice は Observable ではないので、KVO の変化を受けて作り直す。
struct DeviceSnapshot {
    let localizedName: String
    let uniqueID: String
    let modelID: String
    let deviceType: String
    let position: String
    let isConnected: Bool
    let isVirtual: Bool
    let constituentDevices: [String]
    let switchingBehavior: String
    let restrictedConditions: String
    let activeSwitchingBehavior: String
    let activeRestrictedConditions: String
    let activePrimaryConstituent: String
    let supportsSwitching: Bool
    let supportsLockWithDevice: String
    let supportedFallbackPrimaryConstituentDevices: [String]
    let fallbackPrimaryConstituentDevices: [String]
    let switchOverZoomFactors: [CGFloat]
    let videoZoomFactor: CGFloat
    let minAvailableVideoZoomFactor: CGFloat
    let maxAvailableVideoZoomFactor: CGFloat
    let displayVideoZoomFactorMultiplier: CGFloat
    let activeFormat: String

    init(device: AVCaptureDevice) {
        localizedName = device.localizedName
        uniqueID = device.uniqueID
        modelID = device.modelID
        deviceType = device.deviceType.shortName
        position = device.position.title
        isConnected = device.isConnected
        isVirtual = device.isVirtualDevice
        constituentDevices = device.constituentDevices.map(\.shortDescription)
        switchingBehavior = device.primaryConstituentDeviceSwitchingBehavior.title
        restrictedConditions = device.primaryConstituentDeviceRestrictedSwitchingBehaviorConditions.title
        activeSwitchingBehavior = device.activePrimaryConstituentDeviceSwitchingBehavior.title
        activeRestrictedConditions = device.activePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions.title
        activePrimaryConstituent = device.activePrimaryConstituent?.shortDescription ?? "nil"
        supportsSwitching = device.primaryConstituentDeviceSwitchingBehavior != .unsupported
        if #available(iOS 27.0, *) {
            supportsLockWithDevice = String(device.isPrimaryConstituentDeviceSwitchingBehaviorLockedWithDeviceSupported)
        } else {
            supportsLockWithDevice = "requires iOS 27"
        }
        supportedFallbackPrimaryConstituentDevices = device.supportedFallbackPrimaryConstituentDevices.map(\.shortDescription)
        fallbackPrimaryConstituentDevices = device.fallbackPrimaryConstituentDevices.map(\.shortDescription)
        switchOverZoomFactors = device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.doubleValue) }
        videoZoomFactor = device.videoZoomFactor
        minAvailableVideoZoomFactor = device.minAvailableVideoZoomFactor
        maxAvailableVideoZoomFactor = device.maxAvailableVideoZoomFactor
        displayVideoZoomFactorMultiplier = device.displayVideoZoomFactorMultiplier
        let dimensions = device.activeFormat.formatDescription.dimensions
        activeFormat = "\(dimensions.width)x\(dimensions.height)"
    }
}

// MARK: - Captured photo

/// 撮影結果。delegate のキュー (メイン以外) で組み立ててメインに渡すので Sendable にしておく。
struct CapturedPhoto: Identifiable, Sendable {
    let id = UUID()
    let image: UIImage
    /// どの物理カメラで撮られたか (virtual device なら activePrimaryConstituent 相当)。
    let sourceDeviceType: String
    let photoDimensions: String
    /// EXIF の Orientation タグ (1...8)。
    let exifOrientation: Int?
    /// 撮影時に photo connection へ指定した videoRotationAngle。指定できなかったときは nil。
    let requestedRotationAngle: CGFloat?
}

// MARK: - Capture engine

enum CameraError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case noPhotoData

    var errorDescription: String? {
        switch self {
        case .deviceNotFound: "device not found"
        case .cannotAddInput: "session.canAddInput == false"
        case .cannotAddOutput: "session.canAddOutput == false"
        case .noPhotoData: "fileDataRepresentation() returned nil"
        }
    }
}

/// AVCaptureSession を直列キューの上で操作する。
/// AVCaptureSession / AVCaptureDeviceInput は Sendable ではないため、キューの外には出さず、
/// デバイスは uniqueID で受け取って中で引き直す。
nonisolated final class CaptureEngine: @unchecked Sendable {
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()

    private let queue = DispatchQueue(label: "ios-resizable-demo.camera.session")
    /// queue 上でだけ触る。
    private var input: AVCaptureDeviceInput?

    func connect(deviceUniqueID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            queue.async { [self] in
                do {
                    guard let device = AVCaptureDevice(uniqueID: deviceUniqueID) else {
                        throw CameraError.deviceNotFound
                    }
                    let newInput = try AVCaptureDeviceInput(device: device)

                    session.beginConfiguration()
                    if let input {
                        session.removeInput(input)
                        self.input = nil
                    }
                    guard session.canAddInput(newInput) else {
                        session.commitConfiguration()
                        throw CameraError.cannotAddInput
                    }
                    session.addInput(newInput)
                    input = newInput
                    if session.canSetSessionPreset(.photo) {
                        session.sessionPreset = .photo
                    }
                    if !session.outputs.contains(photoOutput) {
                        guard session.canAddOutput(photoOutput) else {
                            session.commitConfiguration()
                            throw CameraError.cannotAddOutput
                        }
                        session.addOutput(photoOutput)
                    }
                    session.commitConfiguration()

                    if !session.isRunning {
                        session.startRunning()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func disconnect() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [self] in
                if session.isRunning {
                    session.stopRunning()
                }
                session.beginConfiguration()
                if let input {
                    session.removeInput(input)
                    self.input = nil
                }
                session.commitConfiguration()
                continuation.resume()
            }
        }
    }

    func capturePhoto(requestedRotationAngle: CGFloat?) async throws -> CapturedPhoto {
        let delegate = PhotoCaptureDelegate(requestedRotationAngle: requestedRotationAngle)
        return try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            // delegate は photoOutput が完了まで保持する。
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
        }
    }
}

private nonisolated final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let requestedRotationAngle: CGFloat?
    var continuation: CheckedContinuation<CapturedPhoto, any Error>?

    init(requestedRotationAngle: CGFloat?) {
        self.requestedRotationAngle = requestedRotationAngle
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard let continuation else { return }
        self.continuation = nil

        if let error {
            continuation.resume(throwing: error)
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            continuation.resume(throwing: CameraError.noPhotoData)
            return
        }
        let dimensions = photo.resolvedSettings.photoDimensions
        continuation.resume(returning: CapturedPhoto(
            image: image,
            sourceDeviceType: photo.sourceDeviceType?.shortName ?? "nil",
            photoDimensions: "\(dimensions.width)x\(dimensions.height)",
            exifOrientation: photo.metadata[kCGImagePropertyOrientation as String] as? Int,
            requestedRotationAngle: requestedRotationAngle
        ))
    }
}

// MARK: - Descriptions

nonisolated extension AVCaptureDevice {
    /// "Back Triple Camera (builtInTripleCamera)" のような一覧向けの短い説明。
    var shortDescription: String {
        "\(localizedName) (\(deviceType.shortName))"
    }
}

nonisolated extension AVCaptureDevice.DeviceType {
    /// "AVCaptureDeviceType" の接頭辞を落とした名前。
    var shortName: String {
        let prefix = "AVCaptureDeviceType"
        guard rawValue.hasPrefix(prefix) else { return rawValue }
        let name = rawValue.dropFirst(prefix.count)
        return name.prefix(1).lowercased() + name.dropFirst()
    }
}

nonisolated extension AVCaptureDevice.Position {
    var title: String {
        switch self {
        case .unspecified: ".unspecified"
        case .back: ".back"
        case .front: ".front"
        @unknown default: "unknown(\(rawValue))"
        }
    }
}

nonisolated extension AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior {
    var title: String {
        switch self {
        case .unsupported: ".unsupported"
        case .auto: ".auto"
        case .restricted: ".restricted"
        case .locked: ".locked"
        @unknown default: "unknown(\(rawValue))"
        }
    }
}

nonisolated extension AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions {
    var title: String {
        var names: [String] = []
        if contains(.videoZoomChanged) { names.append(".videoZoomChanged") }
        if contains(.focusModeChanged) { names.append(".focusModeChanged") }
        if contains(.exposureModeChanged) { names.append(".exposureModeChanged") }
        return names.isEmpty ? "[] (none)" : names.joined(separator: ", ")
    }
}

nonisolated extension AVAuthorizationStatus {
    var title: String {
        switch self {
        case .notDetermined: ".notDetermined"
        case .restricted: ".restricted"
        case .denied: ".denied"
        case .authorized: ".authorized"
        @unknown default: "unknown(\(rawValue))"
        }
    }
}
