import AVFoundation
import SwiftUI

// AVCapture の挙動を確認する画面。
// 中央にプレビューを置き、下 (regular 幅なら右) のリストで
// DiscoverySession の条件 → 見つかったデバイスのプロパティ → セッション接続 → 切り替え挙動の設定 → 撮影 を順に操作する。
// 写真の保存はしない。撮影結果はシートで見るだけ。

struct CameraScreen: View {
    @State private var controller = CameraController()

    @State private var switchingBehavior: SwitchingBehaviorOption = .auto
    @State private var videoZoomChanged = false
    @State private var focusModeChanged = false
    @State private var exposureModeChanged = false
    @State private var lockTarget: String?
    @State private var previewSize: CGSize = .zero

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    HStack(spacing: 0) {
                        preview
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        settingsList
                            .frame(width: 400)
                    }
                } else {
                    VStack(spacing: 0) {
                        preview
                            .frame(maxWidth: .infinity)
                            .frame(height: verticalSizeClass == .compact ? 200 : 360)
                        settingsList
                    }
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await controller.requestAccessIfNeeded()
        }
        .sheet(item: $controller.capturedPhoto) { photo in
            CapturedPhotoSheet(photo: photo)
        }
    }

    // MARK: - Preview

    private var preview: some View {
        ZStack {
            Color.black
            CameraPreviewView(previewLayer: controller.previewLayer)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { size in
                    previewSize = size
                }

            if controller.connectedDevice == nil {
                Text("no session")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack {
                HStack {
                    previewBadge
                    Spacer()
                }
                Spacer()
                captureButton
            }
            .padding(12)
        }
        .clipped()
    }

    private var previewBadge: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(controller.connectedDevice?.shortDescription ?? "(none)")
            Text("running: \(String(controller.isSessionRunning))")
            Text("preview angle: \(controller.previewConnectionRotationAngle.map { "\(Int($0))" } ?? "nil") / coordinator: \(Int(controller.previewRotationAngle))")
            Text("size: \(Int(previewSize.width))x\(Int(previewSize.height))")
        }
        .font(.caption2.monospaced())
        .foregroundStyle(.white)
        .padding(6)
        .background(.black.opacity(0.5), in: .rect(cornerRadius: 6))
    }

    private var captureButton: some View {
        Button {
            controller.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 60, height: 60)
                Circle()
                    .fill(.white)
                    .frame(width: 48, height: 48)
                if controller.isCapturing {
                    ProgressView()
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!controller.isSessionRunning || controller.isCapturing)
        .opacity(controller.isSessionRunning ? 1 : 0.4)
    }

    // MARK: - Settings

    private var settingsList: some View {
        List {
            Section("Status") {
                infoRow("authorization", controller.authorizationStatus.title)
                infoRow("session.isRunning", String(controller.isSessionRunning))
                infoRow("connected device", controller.connectedDevice?.shortDescription ?? "nil")
                infoRow("horizontalSizeClass", horizontalSizeClass.map { String(describing: $0) } ?? "nil")
            }

            discoverySection
            discoveredDevicesSection

            if let snapshot = controller.snapshot {
                deviceSection(snapshot)
                switchingBehaviorSection(snapshot)
                zoomSection(snapshot)
            }

            rotationSection

            Section("Log") {
                ForEach(Array(controller.logLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Discovery

    private var discoverySection: some View {
        Section("DiscoverySession") {
            Picker(selection: $controller.position) {
                ForEach(PositionOption.allCases) { option in
                    Text(".\(option.rawValue)").tag(option)
                }
            } label: {
                Text("position")
                    .font(.footnote.monospaced())
            }

            DisclosureGroup {
                // 状態は持たず、deviceTypes を丸ごと書き換えるだけ。
                HStack {
                    Button("Select all") {
                        controller.deviceTypes = Set(CameraDeviceTypeOption.allCases)
                    }
                    Spacer()
                    Button("Unselect all") {
                        controller.deviceTypes = []
                    }
                }
                .buttonStyle(.borderless)
                .font(.footnote)

                ForEach(CameraDeviceTypeOption.allCases) { option in
                    Toggle(isOn: deviceTypeBinding(option)) {
                        HStack {
                            Text(".\(option.rawValue)")
                                .font(.footnote.monospaced())
                            if let note = option.note {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            } label: {
                infoRow("deviceTypes", "\(controller.deviceTypes.count) selected")
            }

            Button("Run DiscoverySession") {
                controller.runDiscoverySession()
            }
            .disabled(controller.deviceTypes.isEmpty)

            infoRow("result", controller.discoverySummary)
        }
    }

    private func deviceTypeBinding(_ option: CameraDeviceTypeOption) -> Binding<Bool> {
        Binding {
            controller.deviceTypes.contains(option)
        } set: { isOn in
            if isOn {
                controller.deviceTypes.insert(option)
            } else {
                controller.deviceTypes.remove(option)
            }
        }
    }

    private var discoveredDevicesSection: some View {
        Section("Devices (tap to select)") {
            if controller.discoveredDevices.isEmpty {
                Text("(none)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.tertiary)
            }
            ForEach(controller.discoveredDevices, id: \.uniqueID) { device in
                Button {
                    controller.selectedDevice = device
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.localizedName)
                                .foregroundStyle(.primary)
                            Text("\(device.deviceType.shortName) \(device.position.title) virtual=\(String(device.isVirtualDevice))")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if device == controller.connectedDevice {
                            Text("connected")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.2), in: .capsule)
                        }
                        if device == controller.selectedDevice {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
    }

    // MARK: Device

    private func deviceSection(_ snapshot: DeviceSnapshot) -> some View {
        Section {
            if let device = controller.selectedDevice, device != controller.connectedDevice {
                Button("Connect to preview session") {
                    controller.connect(device)
                }
                .disabled(controller.isBusy || controller.authorizationStatus != .authorized)
            }
            if controller.connectedDevice != nil {
                Button("Disconnect", role: .destructive) {
                    controller.disconnect()
                }
                .disabled(controller.isBusy)
            }

            infoRow("localizedName", snapshot.localizedName)
            infoRow("deviceType", snapshot.deviceType)
            infoRow("position", snapshot.position)
            infoRow("modelID", snapshot.modelID)
            infoRow("uniqueID", snapshot.uniqueID)
            infoRow("isConnected", String(snapshot.isConnected))
            infoRow("isVirtual", String(snapshot.isVirtual))
            listRow("constituentDevices", snapshot.constituentDevices)
            infoRow("activeFormat", snapshot.activeFormat)
            infoRow("primaryConstituentDeviceSwitchingBehavior", snapshot.switchingBehavior)
            infoRow("primaryConstituentDeviceRestrictedSwitchingBehaviorConditions", snapshot.restrictedConditions)
            infoRow("activePrimaryConstituentDeviceSwitchingBehavior", snapshot.activeSwitchingBehavior)
            infoRow("activePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions", snapshot.activeRestrictedConditions)
            infoRow("activePrimaryConstituentDevice", snapshot.activePrimaryConstituent)
            listRow("supportedFallbackPrimaryConstituentDevices", snapshot.supportedFallbackPrimaryConstituentDevices)
            listRow("fallbackPrimaryConstituentDevices", snapshot.fallbackPrimaryConstituentDevices)
            infoRow("isPrimaryConstituentDeviceSwitchingBehaviorLockedWithDeviceSupported", snapshot.supportsLockWithDevice)
        } header: {
            Text("Selected: \(snapshot.localizedName)")
        }
    }

    // MARK: Switching behavior

    private func switchingBehaviorSection(_ snapshot: DeviceSnapshot) -> some View {
        Section {
            if !snapshot.supportsSwitching {
                Text("primaryConstituentDeviceSwitchingBehavior == .unsupported (not a virtual device with multiple constituents)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Picker(selection: $switchingBehavior) {
                ForEach(SwitchingBehaviorOption.allCases) { option in
                    Text(".\(option.rawValue)").tag(option)
                }
            } label: {
                Text("behavior")
                    .font(.footnote.monospaced())
            }

            Group {
                Toggle(".videoZoomChanged", isOn: $videoZoomChanged)
                Toggle(".focusModeChanged", isOn: $focusModeChanged)
                Toggle(".exposureModeChanged", isOn: $exposureModeChanged)
            }
            .font(.footnote.monospaced())
            // conditions は .restricted のときだけ意味を持つ (それ以外で渡すと例外になるので controller 側で落とす)。
            .disabled(switchingBehavior != .restricted)

            Button("setPrimaryConstituentDeviceSwitchingBehavior(_:restrictedSwitchingBehaviorConditions:)") {
                controller.setSwitchingBehavior(switchingBehavior.value, conditions: selectedConditions)
            }
            .font(.footnote.monospaced())
            .disabled(!snapshot.supportsSwitching)

            lockWithDeviceRows(snapshot)
        } header: {
            Text("Switching behavior (set)")
        }
    }

    @ViewBuilder
    private func lockWithDeviceRows(_ snapshot: DeviceSnapshot) -> some View {
        if #available(iOS 27.0, *), let device = controller.selectedDevice {
            let constituents = device.constituentDevices
            Picker(selection: $lockTarget) {
                Text("(none)").tag(String?.none)
                ForEach(constituents, id: \.uniqueID) { constituent in
                    Text(constituent.shortDescription).tag(Optional(constituent.uniqueID))
                }
            } label: {
                Text("lock target")
                    .font(.footnote.monospaced())
            }

            Button("setPrimaryConstituentDeviceSwitchingBehaviorLockedWith(_:)") {
                if let constituent = constituents.first(where: { $0.uniqueID == lockTarget }) {
                    controller.lockSwitchingBehavior(to: constituent)
                }
            }
            .font(.footnote.monospaced())
            .disabled(!device.isPrimaryConstituentDeviceSwitchingBehaviorLockedWithDeviceSupported || lockTarget == nil)
        } else {
            unavailableRow("setPrimaryConstituentDeviceSwitchingBehaviorLockedWith(_:)", "requires iOS 27")
        }
    }

    private var selectedConditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions {
        var conditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions = []
        if videoZoomChanged { conditions.insert(.videoZoomChanged) }
        if focusModeChanged { conditions.insert(.focusModeChanged) }
        if exposureModeChanged { conditions.insert(.exposureModeChanged) }
        return conditions
    }

    // MARK: Zoom

    private func zoomSection(_ snapshot: DeviceSnapshot) -> some View {
        Section("Zoom") {
            // ズームを動かすと virtual device の activePrimaryConstituentDevice が切り替わる。
            // .locked にすると minAvailableVideoZoomFactor が切り替え点まで上がる。
            Slider(
                value: Binding(
                    get: { snapshot.videoZoomFactor },
                    set: { controller.setZoom($0) }
                ),
                in: snapshot.minAvailableVideoZoomFactor...max(snapshot.minAvailableVideoZoomFactor, snapshot.maxAvailableVideoZoomFactor)
            )
            infoRow("videoZoomFactor", zoomString(snapshot.videoZoomFactor))
            infoRow("minAvailableVideoZoomFactor", zoomString(snapshot.minAvailableVideoZoomFactor))
            infoRow("maxAvailableVideoZoomFactor", zoomString(snapshot.maxAvailableVideoZoomFactor))
            infoRow("displayVideoZoomFactorMultiplier", zoomString(snapshot.displayVideoZoomFactorMultiplier))
            infoRow("virtualDeviceSwitchOverVideoZoomFactors", snapshot.switchOverZoomFactors.map { zoomString($0) }.joined(separator: ", "))
        }
    }

    // MARK: Rotation

    private var rotationSection: some View {
        Section("Rotation") {
            Picker(selection: $controller.previewRotation) {
                ForEach(RotationSource.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            } label: {
                Text("preview videoRotationAngle")
                    .font(.footnote.monospaced())
            }
            Picker(selection: $controller.captureRotation) {
                ForEach(RotationSource.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            } label: {
                Text("capture videoRotationAngle")
                    .font(.footnote.monospaced())
            }
            infoRow("coordinator.videoRotationAngleForHorizonLevelPreview", "\(Int(controller.previewRotationAngle))")
            infoRow("coordinator.videoRotationAngleForHorizonLevelCapture", "\(Int(controller.captureRotationAngle))")
            infoRow("previewLayer.connection.videoRotationAngle", controller.previewConnectionRotationAngle.map { "\(Int($0))" } ?? "nil")
            infoRow("preview size", "\(Int(previewSize.width))x\(Int(previewSize.height))")
        }
    }
}

// MARK: - Captured photo sheet

private struct CapturedPhotoSheet: View {
    let photo: CapturedPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Image(uiImage: photo.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)

                List {
                    infoRow("sourceDeviceType", photo.sourceDeviceType)
                    infoRow("photoDimensions", photo.photoDimensions)
                    infoRow("image.size", "\(Int(photo.image.size.width))x\(Int(photo.image.size.height))")
                    infoRow("image.imageOrientation", photo.image.imageOrientation.title)
                    infoRow("EXIF Orientation", photo.exifOrientation.map(String.init) ?? "nil")
                    infoRow("requested videoRotationAngle", photo.requestedRotationAngle.map { "\(Int($0))" } ?? "nil")
                }
                .frame(height: 300)
            }
            .navigationTitle("Captured")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview view

/// controller が持つ AVCaptureVideoPreviewLayer をそのまま sublayer として載せるだけのビュー。
private struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewHostView {
        PreviewHostView(previewLayer: previewLayer)
    }

    func updateUIView(_ uiView: PreviewHostView, context: Context) {}
}

private final class PreviewHostView: UIView {
    private let previewLayer: AVCaptureVideoPreviewLayer

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        super.init(frame: .zero)
        backgroundColor = .black
        layer.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // リサイズ時に暗黙アニメーションでプレビューが遅れて追従しないようにする。
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Options

private enum SwitchingBehaviorOption: String, CaseIterable, Identifiable {
    case auto
    case restricted
    case locked

    var id: String { rawValue }

    var value: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior {
        switch self {
        case .auto: .auto
        case .restricted: .restricted
        case .locked: .locked
        }
    }
}

private extension UIImage.Orientation {
    var title: String {
        switch self {
        case .up: ".up"
        case .down: ".down"
        case .left: ".left"
        case .right: ".right"
        case .upMirrored: ".upMirrored"
        case .downMirrored: ".downMirrored"
        case .leftMirrored: ".leftMirrored"
        case .rightMirrored: ".rightMirrored"
        @unknown default: "unknown(\(rawValue))"
        }
    }
}

// MARK: - Shared rows

private func infoRow(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(title)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
        Text(value)
            .font(.footnote.monospaced())
            .textSelection(.enabled)
    }
}

private func listRow(_ title: String, _ values: [String]) -> some View {
    infoRow(title, values.isEmpty ? "[]" : values.joined(separator: "\n"))
}

private func zoomString(_ value: CGFloat) -> String {
    String(format: "%.2f", value)
}

private func unavailableRow(_ title: String, _ reason: String) -> some View {
    infoRow(title, reason)
        .foregroundStyle(.tertiary)
}
