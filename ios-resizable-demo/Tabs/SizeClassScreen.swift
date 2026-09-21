import SwiftUI

struct SizeClassScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var windowBounds: CGRect = .zero
    @State private var observedWindowBounds: CGRect = .zero

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

                    let screenBounds = UIScreen.main.bounds
                    infoRow("UIScreen.main.bounds", "\(format(screenBounds.width))  × \(format(screenBounds.height))")

                    let keyWindowBounds = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.coordinateSpace.bounds ?? CGRect()
                    infoRow("keyWindow.bounds", "\(format(keyWindowBounds.width))  × \(format(keyWindowBounds.height))")


                    infoRow("window.layer.bounds (KVO)", "\(format(observedWindowBounds.width))  × \(format(observedWindowBounds.height))")

                    TempSection(bounds: observedWindowBounds)
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
        .onWindowBoundsChange { bounds in
            observedWindowBounds = bounds
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
extension View {
    /// 自身が所属する UIWindow の bounds の変化をクロージャーへ通知する。
    /// ウィンドウのリサイズは SwiftUI の再描画を発火しないため、layer.bounds を KVO で監視する。
    func onWindowBoundsChange(onChangeBounds: @escaping (CGRect) -> Void) -> some View {
        background(WindowReader(onChangeBounds: onChangeBounds))
    }
}

private struct WindowReader: UIViewRepresentable {
    var onChangeBounds: (CGRect) -> Void

    func makeUIView(context: Context) -> WindowObservingView {
        let view = WindowObservingView()
        view.onChangeBounds = onChangeBounds
        return view
    }

    func updateUIView(_ uiView: WindowObservingView, context: Context) {
        uiView.onChangeBounds = onChangeBounds
    }

    final class WindowObservingView: UIView {
        var onChangeBounds: ((CGRect) -> Void)?
        private var boundsObservation: NSKeyValueObservation?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window else {
                boundsObservation = nil
                return
            }
            // .initial により、ウィンドウに追加された時点の bounds も通知される。
            boundsObservation = window.layer.observe(\.bounds, options: [.initial, .new]) { [weak self] layer, _ in
                self?.onChangeBounds?(layer.bounds)
            }
        }
    }
}

struct TempSection: View {
    var bounds: CGRect?

    var body: some View {
        let windowBounds = bounds ?? CGRect()
        infoRow("window.bounds", "\(format(windowBounds.width))  × \(format(windowBounds.height))")
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
}
