import SwiftUI
import UIKit

struct ContentAreaScreen: View {
    @State var addnavigationTitle = true
    @State var disableToolbarVerticalBehavior = false

    var content: some View {
        Group {
            if #available(iOS 27.1, *) {
                ContentAreaGeometryView(
                    addNavigationTitle: $addnavigationTitle,
                    disableToolbarVerticalBehavior: $disableToolbarVerticalBehavior
                )
                .toolbarVerticalBehavior(disableToolbarVerticalBehavior ? .disabled : .automatic)
            } else {
                ZStack {
                    Color.red

                    Toggle("Add navigation title", isOn: $addnavigationTitle)
                }
            }
        }
        .toolbarBackground(Color.blue, for: .navigationBar)
    }

    var body: some View {
        NavigationStack {
            if addnavigationTitle {
                content
                    .navigationTitle("Navigation Title")
                    .navigationBarTitleDisplayMode(.inline)
            }
            else {
                content
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

@available(iOS 27.1, *)
struct ContentAreaGeometryView: View {
    @Binding var addNavigationTitle: Bool
    @Binding var disableToolbarVerticalBehavior: Bool
    @State private var reservedRegions: [UIView.ReservedRegion] = []
    @State private var cornerInsets = RectangleCornerInsets()

    var body: some View {
        GeometryReader { proxy in
            let safeAreaInsets = proxy.safeAreaInsets
            let fullSize = CGSize(
                width: proxy.size.width + safeAreaInsets.leading + safeAreaInsets.trailing,
                height: proxy.size.height + safeAreaInsets.top + safeAreaInsets.bottom
            )

            ZStack(alignment: .topLeading) {
                Color.orange

                Color.cyan
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .offset(x: safeAreaInsets.leading, y: safeAreaInsets.top)

                cornerMark(cornerInsets.topLeading, alignment: .topLeading)
                cornerMark(cornerInsets.topTrailing, alignment: .topTrailing)
                cornerMark(cornerInsets.bottomLeading, alignment: .bottomLeading)
                cornerMark(cornerInsets.bottomTrailing, alignment: .bottomTrailing)

                reservedRegionMarks

                infoPanel(safeAreaInsets: safeAreaInsets)
            }
            .frame(width: fullSize.width, height: fullSize.height)
            // Shift the drawing space so its origin matches the full container bounds
            .offset(x: -safeAreaInsets.leading, y: -safeAreaInsets.top)
        }
        .background {
            // Reserved regions are only exposed through UIKit,
            // so read them from a full-bleed UIView sharing the same coordinate space
            ReservedRegionReaderView(regions: $reservedRegions)
                // containerCornerInsets reports only the portion overlapping this view,
                // so read it from the full-bleed view rather than the safe-area-inset one
                .onGeometryChange(for: RectangleCornerInsets.self) { fullProxy in
                    fullProxy.containerCornerInsets
                } action: { newValue in
                    cornerInsets = newValue
                }
                .ignoresSafeArea()
        }
    }

    private func cornerMark(_ size: CGSize, alignment: Alignment) -> some View {
        Color.purple.opacity(0.6)
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    private var reservedRegionMarks: some View {
        // Border + light fill so the corner inset marks underneath stay visible
        ForEach(reservedRegions) { region in
            Rectangle()
                .fill(Color.red.opacity(region.isActive ? 0.3 : 0.1))
                .overlay {
                    Rectangle()
                        .strokeBorder(
                            Color.red,
                            style: StrokeStyle(lineWidth: 2, dash: region.isActive ? [] : [6, 4])
                        )
                }
                .overlay {
                    Text("\(region.kind.description) \(region.isActive ? "active" : "inactive")")
                        .font(.caption2)
                        .minimumScaleFactor(0.3)
                }
                .frame(width: region.frame.width, height: region.frame.height)
                .position(x: region.frame.midX, y: region.frame.midY)
        }
    }

    private func infoPanel(safeAreaInsets: EdgeInsets) -> some View {
        VStack(spacing: 8) {
            Toggle("Add navigation title", isOn: $addNavigationTitle)
                .fixedSize()

            Toggle("Disable vertical control", isOn: $disableToolbarVerticalBehavior)
                .fixedSize()
                .padding(.bottom, 8)

            heading("safeAreaInsets", color: .orange)
            Text("top: \(points(safeAreaInsets.top))")
            Text("leading: \(points(safeAreaInsets.leading))")
            Text("bottom: \(points(safeAreaInsets.bottom))")
            Text("trailing: \(points(safeAreaInsets.trailing))")

            heading("containerCornerInsets", color: .purple)
                .padding(.top, 8)
            Text("topLeading: \(sizeText(cornerInsets.topLeading))")
            Text("topTrailing: \(sizeText(cornerInsets.topTrailing))")
            Text("bottomLeading: \(sizeText(cornerInsets.bottomLeading))")
            Text("bottomTrailing: \(sizeText(cornerInsets.bottomTrailing))")

            heading("reservedRegions", color: .red)
                .padding(.top, 8)
            if reservedRegions.isEmpty {
                Text("none")
                    .font(.caption)
            } else {
                ForEach(reservedRegions) { region in
                    Text("\(region.kind.description) \(region.isActive ? "active" : "inactive"): \(originText(region.frame.origin)) \(sizeText(region.frame.size))")
                        .font(.caption)
                }
            }
        }
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func heading(_ title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.headline)
        }
    }

    private func points(_ value: CGFloat) -> String {
        String(format: "%.1f pt", value)
    }

    private func sizeText(_ size: CGSize) -> String {
        String(format: "%.1f × %.1f pt", size.width, size.height)
    }

    private func originText(_ point: CGPoint) -> String {
        String(format: "(%.1f, %.1f)", point.x, point.y)
    }
}

@available(iOS 27.1, *)
private struct ReservedRegionReaderView: UIViewRepresentable {
    @Binding var regions: [UIView.ReservedRegion]

    func makeUIView(context: Context) -> RegionObservingView {
        let view = RegionObservingView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: RegionObservingView, context: Context) {
        uiView.onRegionsChange = { newRegions in
            if regions != newRegions {
                regions = newRegions
            }
        }
        uiView.setNeedsLayout()
    }

    final class RegionObservingView: UIView {
        var onRegionsChange: (([UIView.ReservedRegion]) -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            let regions = reservedRegions(kind: .occlusion, options: .includeInactive)
                + reservedRegions(kind: .division, options: .includeInactive)
            // Defer to avoid mutating SwiftUI state during a view update pass
            Task {
                onRegionsChange?(regions)
            }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            setNeedsLayout()
        }
    }
}
