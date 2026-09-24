import SwiftUI

struct ParametersScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // UIScreen.main.bounds などは State ではないため、値を変えて body を再評価させるためだけのトリガー。
    @State private var refreshTrigger = 0

    var body: some View {
        NavigationStack {
            List {
                if #available(iOS 27.1, *) {
                    DuoParametersSection()
                }

                Section("Size Class") {
                    infoRow("horizontal", label(for: horizontalSizeClass))
                    infoRow("vertical", label(for: verticalSizeClass))
                }

                Section("Window bounds") {
                    boundsRow("UIScreen.main.bounds", UIScreen.main.bounds)

                    let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                    let keyWindowBounds = windowScenes.first?.coordinateSpace.bounds ?? CGRect()
                    boundsRow("keyWindow.bounds", keyWindowBounds)

                    let otherWindows = windowScenes.flatMap(\.windows).filter { !$0.isKeyWindow }
                    ForEach(otherWindows, id: \.self) { window in
                        boundsRow(String(describing: type(of: window)), window.bounds)
                    }

                    Button("Refresh") {
                        refreshTrigger += 1
                    }
                }
                .id(refreshTrigger)
            }
            .navigationTitle("Parameters")
        }
    }

    private func boundsRow(_ title: String, _ bounds: CGRect) -> some View {
        infoRow(title, "\(format(bounds.width)) × \(format(bounds.height))")
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

    private func format(_ value: CGFloat) -> String {
        String(format: "%.1f", value)
    }

    private func label(for sizeClass: UserInterfaceSizeClass?) -> String {
        switch sizeClass {
        case .compact: "compact"
        case .regular: "regular"
        default: "unknown"
        }
    }
}

@available(iOS 27.1, *)
private struct DuoParametersSection: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    @State private var hinge: DeviceHinge?

    var body: some View {
        Section("iPhone Duo (iOS 27.1)") {
            infoRow("hinge.status", hinge.map { String(describing: $0.status) } ?? "nil (no hinge)")
                // ヒンジを持たないデバイスでは hinge が nil のまま通知される。
                .onHingeChange { _, newContext in
                    hinge = newContext.hinge
                }
            infoRow("hinge.angle", hinge.map { String(format: "%.1f°", $0.angle.degrees) } ?? "nil (no hinge)")
            infoRow("toolbarVerticalEdge", toolbarVerticalEdge.map { String(describing: $0) } ?? "nil")
        }
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
}
