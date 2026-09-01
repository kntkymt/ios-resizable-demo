import SwiftUI

struct SizeClassScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var windowBounds: CGRect = .zero

    var body: some View {
        NavigationStack {
            List {
                Section("Size Class") {
                    infoRow("horizontal", label(for: horizontalSizeClass))
                    infoRow("vertical", label(for: verticalSizeClass))
                }

                Section("Window bounds") {
                    infoRow("origin", "(\(format(windowBounds.origin.x)), \(format(windowBounds.origin.y)))")
                    infoRow("size", "\(format(windowBounds.width)) × \(format(windowBounds.height))")
                }
            }
            .navigationTitle("Size Class")
        }
        // ルートビューはウィンドウ全体を占めるため、global 座標の frame がウィンドウの bounds と一致する。
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            windowBounds = frame
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

