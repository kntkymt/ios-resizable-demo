import SwiftUI
import UIKit

struct PresentationStylesScreen: View {
    @State private var isSheetPresented = false
    @State private var isFullScreenCoverPresented = false
    @State private var isPopoverPresented = false
    @State private var isConfirmationDialogPresented = false
    @State private var isReferenceAlertPresented = false
    @State private var modalStyle: ModalStyleOption = .automatic
    @State private var adaptation: AdaptationOption = .automatic
    @State private var selectedDetents: Set<DetentOption> = []
    @State private var detentHeightText: String = "200"

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        NavigationStack {
            List {
                Section("Size Class") {
                    infoRow("horizontal", label(for: horizontalSizeClass))
                    infoRow("vertical", label(for: verticalSizeClass))
                }


                Section("Share with UIKit") {
                    ViewControllerProvider { controller in
                        Button {
                            guard let controller else { return }

                            let activityController = UIActivityViewController(
                                activityItems: ["This is a sample text shared via the UIKit UIActivityViewController."],
                                applicationActivities: nil
                            )

                            // iPad ではポップオーバー起点の指定が必須。
                            // controller.view はボタンと同じフレームなので、矢印がボタンを指す。
                            if let popover = activityController.popoverPresentationController {
                                popover.sourceView = controller.view
                                popover.sourceRect = controller.view.bounds
                            }

                            controller.present(activityController, animated: true)
                        } label: {
                            Label("Share with UIKit", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("Share with SwiftUI (ShareLink)") {
                    ShareLink(item: "This is a sample text shared via the SwiftUI ShareLink") {
                        Label("Share with ShareLink", systemImage: "square.and.arrow.up")
                    }
                }

                Section("UIKit present Demo") {
                    Picker("modalPresentationStyle", selection: $modalStyle) {
                        ForEach(ModalStyleOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }

                    ViewControllerProvider { controller in
                        Button {
                            guard let controller else { return }

                            let hostingController = UIHostingController(
                                rootView: PresentedDemoScreen(
                                    title: "UIKit Modal",
                                    message: "modalPresentationStyle: \(modalStyle.title)"
                                )
                            )
                            hostingController.rootView.onDismiss = { [weak hostingController] in
                                hostingController?.dismiss(animated: true)
                            }
                            hostingController.modalPresentationStyle = modalStyle.value

                            // popover スタイルでは起点の指定が必須。
                            // controller.view はボタンと同じフレームなので、矢印がボタンを指す。
                            if let popover = hostingController.popoverPresentationController {
                                popover.sourceView = controller.view
                                popover.sourceRect = controller.view.bounds
                            }

                            controller.present(hostingController, animated: true)
                        } label: {
                            Label("Present with UIKit", systemImage: "rectangle.portrait.on.rectangle.portrait")
                        }
                    }
                }

                Section("Dialog Demo") {
                    ViewControllerProvider { controller in
                        Button {
                            guard let controller else { return }

                            let hostingController = UIHostingController(rootView: CustomDialogScreen())
                            hostingController.rootView.onDismiss = { [weak hostingController] in
                                hostingController?.dismiss(animated: true)
                            }
                            // .fullScreen だと背面の VC のビューが取り除かれて透けないため、
                            // フルスクリーンサイズで背面を残す .overFullScreen を使う。
                            hostingController.modalPresentationStyle = .overFullScreen
                            // デフォルトの coverVertical だと全画面がスライドしてしまうので、
                            // ダイアログらしくフェードで表示する。
                            hostingController.modalTransitionStyle = .crossDissolve
                            // UIHostingController の view は不透明な背景を持つため、透明にする。
                            hostingController.view.backgroundColor = .clear

                            controller.present(hostingController, animated: true)
                        } label: {
                            Label("Show Custom Dialog", systemImage: "rectangle.center.inset.filled")
                        }
                    }

                    Button {
                        isReferenceAlertPresented = true
                    } label: {
                        Label("Show Native Alert", systemImage: "exclamationmark.bubble")
                    }
                    .alert(
                        "Standard Alert",
                        isPresented: $isReferenceAlertPresented
                    ) {
                        Button("OK") {}
                    } message: {
                        Text("This is a standard alert for comparing the hinge-avoiding behavior.")
                    }
                }

                Section(".sheet Demo") {
                    ForEach(DetentOption.allCases) { option in
                        Toggle(isOn: detentBinding(for: option)) {
                            if option == .height {
                                HStack {
                                    Text(option.title)
                                    TextField("height", text: $detentHeightText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: detentHeightText) { _, newValue in
                                            let filtered = newValue.filter(\.isWholeNumber)
                                            if filtered != newValue {
                                                detentHeightText = filtered
                                            }
                                        }
                                }
                            } else {
                                Text(option.title)
                            }
                        }
                    }

                    Button {
                        isSheetPresented = true
                    } label: {
                        Label("Show Sheet", systemImage: "rectangle.portrait.bottomhalf.inset.filled")
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        sheetContent
                            .presentationDetents(presentationDetents)
                    }
                }

                Section(".fullScreenCover Demo") {
                    Button {
                        isFullScreenCoverPresented = true
                    } label: {
                        Label("Show Full Screen Cover", systemImage: "rectangle.portrait.inset.filled")
                    }
                    .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
                        fullScreenCoverContent
                    }
                }

                Section(".popover Adaptation Demo") {
                    Picker("Adaptation", selection: $adaptation) {
                        ForEach(AdaptationOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button {
                        isPopoverPresented = true
                    } label: {
                        Label("Show Popover", systemImage: "bubble.left.and.bubble.right")
                    }
                    .popover(isPresented: $isPopoverPresented) {
                        popoverContent
                            .presentationCompactAdaptation(adaptation.value)
                            .presentationDetents([.medium])
                    }
                }

                Section(".confirmationDialog Demo") {
                    Button {
                        isConfirmationDialogPresented = true
                    } label: {
                        Label("Show Confirmation Dialog", systemImage: "questionmark.bubble")
                    }
                    .confirmationDialog(
                        "This is a confirmation dialog",
                        isPresented: $isConfirmationDialogPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Action A", role: .destructive) {
                        }
                        Button("Action B") {
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This is a message")
                    }
                }
            }
            .navigationTitle("Presentation Styles")
        }
    }

    private var sheetContent: some View {
        PresentedDemoScreen(
            title: "Sheet",
            message: "This is the content of the .sheet"
        )
    }

    private var fullScreenCoverContent: some View {
        PresentedDemoScreen(
            title: "Full Screen Cover",
            message: "This is the content of the .fullScreenCover"
        )
    }

    private var popoverContent: some View {
        PresentedDemoScreen(
            title: "Popover",
            message: "This is the content of the popover"
        )
        .frame(minWidth: 260, minHeight: 200)
    }

    // 選択が空だと .presentationDetents が無効になるため、その場合はデフォルトの [.large] を使う。
    private var presentationDetents: Set<PresentationDetent> {
        selectedDetents.isEmpty ? [.large] : Set(selectedDetents.map { $0.value(height: detentHeight) })
    }

    private var detentHeight: CGFloat {
        CGFloat(Double(detentHeightText) ?? 200)
    }

    private func detentBinding(for option: DetentOption) -> Binding<Bool> {
        Binding(
            get: { selectedDetents.contains(option) },
            set: { isOn in
                if isOn {
                    selectedDetents.insert(option)
                } else {
                    selectedDetents.remove(option)
                }
            }
        )
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.monospaced())
        }
    }

    private func label(for sizeClass: UserInterfaceSizeClass?) -> String {
        switch sizeClass {
        case .compact: "compact"
        case .regular: "regular"
        default: "unknown"
        }
    }
}

private struct PresentedDemoScreen: View {
    let title: String
    let message: String
    // UIKit present のように SwiftUI の dismiss では状態が同期できない場合に差し替える。
    var onDismiss: (() -> Void)? = nil

    @State private var titleDisplayMode: TitleDisplayModeOption = .automatic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(message)
                    .font(.headline)

                Picker("Title Display Mode", selection: $titleDisplayMode) {
                    ForEach(TitleDisplayModeOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(titleDisplayMode.value)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

private struct CustomDialogScreen: View {
    // UIKit present では SwiftUI の dismiss で状態が同期できないため UIKit 側で閉じる。
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // スクリムは視覚効果のみなので hinge をまたいでも問題なく、全画面のままにする。
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss?()
                }

            if #available(iOS 27.1, *) {
                ArrangementView {
                    Color.clear
                } secondary: {
                    dialogCard
                        // secondary は固有サイズのまま左上に置かれるため、
                        // 領域いっぱいに広げてその中央にカードを配置する。
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        // 標準の alert に合わせて、折り曲げ時は下側の region へ寄せる。
                        .overlayArrangementEdge(.bottom)
                }
                .arrangementViewStyle(.overlay)
            } else {
                dialogCard
            }
        }
    }

    private var dialogCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            Text("Custom Dialog")
                .font(.headline)

            Text("This dialog is presented with UIKit present using .overFullScreen, so the background stays visible through the transparent area.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onDismiss?()
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 24)
        .padding(40)
    }
}

enum DetentOption: String, CaseIterable, Identifiable {
    case medium
    case large
    case height

    var id: String { rawValue }

    var title: String {
        switch self {
        case .medium: "medium"
        case .large: "large"
        case .height: "height"
        }
    }

    func value(height: CGFloat) -> PresentationDetent {
        switch self {
        case .medium: .medium
        case .large: .large
        case .height: .height(height)
        }
    }
}

enum AdaptationOption: String, CaseIterable, Identifiable {
    case automatic
    case none
    case sheet
    case popover
    case fullScreenCover

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: "automatic"
        case .none: "none"
        case .sheet: "sheet"
        case .popover: "popover"
        case .fullScreenCover: "fullScreenCover"
        }
    }

    var value: PresentationAdaptation {
        switch self {
        case .automatic: .automatic
        case .none: .none
        case .sheet: .sheet
        case .popover: .popover
        case .fullScreenCover: .fullScreenCover
        }
    }
}

enum ModalStyleOption: String, CaseIterable, Identifiable {
    case automatic
    case fullScreen
    case pageSheet
    case formSheet
    case overFullScreen
    case popover

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: "automatic"
        case .fullScreen: "fullScreen"
        case .pageSheet: "pageSheet"
        case .formSheet: "formSheet"
        case .overFullScreen: "overFullScreen"
        case .popover: "popover"
        }
    }

    var value: UIModalPresentationStyle {
        switch self {
        case .automatic: .automatic
        case .fullScreen: .fullScreen
        case .pageSheet: .pageSheet
        case .formSheet: .formSheet
        case .overFullScreen: .overFullScreen
        case .popover: .popover
        }
    }
}

enum TitleDisplayModeOption: String, CaseIterable, Identifiable {
    case automatic
    case inline
    case large

    var id: String { rawValue }

    var title: String { rawValue }

    var value: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .automatic: .automatic
        case .inline: .inline
        case .large: .large
        }
    }
}
