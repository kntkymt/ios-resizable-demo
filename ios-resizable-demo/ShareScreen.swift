import SwiftUI
import UIKit

struct ShareScreen: View {
    @State private var isUIKitSharePresented = false
    @State private var isSheetPresented = false
    @State private var isPopoverPresented = false
    @State private var isConfirmationDialogPresented = false
    @State private var adaptation: AdaptationOption = .automatic

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
                    Button {
                        isUIKitSharePresented = true
                    } label: {
                        Label("Share with UIKit", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Share with SwiftUI (ShareLink)") {
                    ShareLink(item: "This is a sample text shared via the SwiftUI ShareLink") {
                        Label("Share with ShareLink", systemImage: "square.and.arrow.up")
                    }
                }

                Section(".sheet Demo") {
                    Button {
                        isSheetPresented = true
                    } label: {
                        Label("Show Sheet", systemImage: "rectangle.portrait.bottomhalf.inset.filled")
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        sheetContent
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
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
            .navigationTitle("Share Sample")
            .background(
                ActivityViewControllerPresenter(
                    isPresented: $isUIKitSharePresented,
                    activityItems: ["This is a sample text shared via the UIKit UIActivityViewController."]
                )
            )
        }
    }

    private var sheetContent: some View {
        VStack(spacing: 12) {
            Text("This is the content of the .sheet")
                .font(.headline)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var popoverContent: some View {
        VStack(spacing: 12) {
            Text("This is the content of the popover")
                .font(.headline)
        }
        .padding(24)
        .frame(minWidth: 260)
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

struct ActivityViewControllerPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }

        let activityController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // iPad ではポップオーバー起点の指定が必須。
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = uiViewController.view
            popover.sourceRect = CGRect(
                x: uiViewController.view.bounds.midX,
                y: uiViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        activityController.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }

        // updateUIViewController 中の再入を避けるため次のランループで present する。
        DispatchQueue.main.async {
            uiViewController.present(activityController, animated: true)
        }
    }
}
