import SwiftUI

struct ArrangementViewScreen: View {
    var body: some View {
        if #available(iOS 27.1, *) {
            ArrangementDemoView()
        } else {
            ContentUnavailableView(
                "ArrangementView は iOS 27.1 以降で利用できます",
                systemImage: "rectangle.split.2x1"
            )
        }
    }
}

/// ArrangementView の style / axes / edge の組み合わせを切り替えて、
/// primary / secondary がどうレイアウトされるかを色付きパネルで確認するデモ。
@available(iOS 27.1, *)
private struct ArrangementDemoView: View {
    private enum StyleOption: String, CaseIterable, Identifiable {
        case automatic
        case overlay

        var id: Self { self }
    }

    private enum AxesOption: String, CaseIterable, Identifiable {
        case horizontal
        case vertical
        case both

        var id: Self { self }

        var axes: Axis.Set {
            switch self {
            case .horizontal: .horizontal
            case .vertical: .vertical
            case .both: [.horizontal, .vertical]
            }
        }

        var code: String {
            switch self {
            case .horizontal: ".horizontal"
            case .vertical: ".vertical"
            case .both: "[.horizontal, .vertical]"
            }
        }
    }

    private enum HorizontalEdgeOption: String, CaseIterable, Identifiable {
        case unset
        case leading
        case trailing

        var id: Self { self }

        var edge: HorizontalEdge? {
            switch self {
            case .unset: nil
            case .leading: .leading
            case .trailing: .trailing
            }
        }
    }

    private enum VerticalEdgeOption: String, CaseIterable, Identifiable {
        case unset
        case top
        case bottom

        var id: Self { self }

        var edge: VerticalEdge? {
            switch self {
            case .unset: nil
            case .top: .top
            case .bottom: .bottom
            }
        }
    }

    @State private var style: StyleOption = .automatic
    @State private var axes: AxesOption = .both
    @State private var horizontalEdge: HorizontalEdgeOption = .unset
    @State private var verticalEdge: VerticalEdgeOption = .unset
    @State private var isConfigPresented = false

    var body: some View {
        NavigationStack {
            arrangement
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Config", systemImage: "slider.horizontal.3") {
                            isConfigPresented = true
                        }
                    }
                }
                .sheet(isPresented: $isConfigPresented) {
                    controls
                        // sheet 表示中も背後の ArrangementView が見えるよう小さめの detent にする。
                        .presentationDetents([.height(280), .medium])
                }
        }
    }

    @ViewBuilder
    private var arrangement: some View {
        let base = ArrangementView {
            ColorPanel(title: "Primary", color: .blue)
        } secondary: {
            ColorPanel(title: "Secondary", color: .orange)
                // overlay 時に secondary をどの辺に寄せるかの指定。
                .overlayArrangementEdge(horizontalEdge.edge)
                .overlayArrangementEdge(verticalEdge.edge)
        }

        switch style {
        case .automatic:
            base.arrangementViewStyle(.automatic)
        case .overlay:
            base.arrangementViewStyle(.overlay.axes(axes.axes))
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            optionRow("style", selection: $style)
            optionRow("axes (overlay のみ)", selection: $axes)
                .disabled(style != .overlay)
            HStack(spacing: 12) {
                optionRow("secondary horizontal edge", selection: $horizontalEdge)
                optionRow("secondary vertical edge", selection: $verticalEdge)
            }
            Text(appliedCode)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var appliedCode: String {
        var lines: [String] = []
        switch style {
        case .automatic:
            lines.append(".arrangementViewStyle(.automatic)")
        case .overlay:
            lines.append(".arrangementViewStyle(.overlay.axes(\(axes.code)))")
        }
        if horizontalEdge != .unset {
            lines.append("secondary.overlayArrangementEdge(.\(horizontalEdge.rawValue))")
        }
        if verticalEdge != .unset {
            lines.append("secondary.overlayArrangementEdge(.\(verticalEdge.rawValue))")
        }
        return lines.joined(separator: "\n")
    }

    private func optionRow<Option: CaseIterable & Identifiable & RawRepresentable<String> & Hashable>(
        _ title: String,
        selection: Binding<Option>
    ) -> some View where Option.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(Option.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

/// 与えられた領域いっぱいに広がり、自身のサイズを表示する色付きパネル。
private struct ColorPanel: View {
    let title: String
    let color: Color

    @State private var size = CGSize.zero

    var body: some View {
        ZStack {
            // overlay スタイルで重なったときに下のパネルが透けて見えるよう半透明にする。
            color.opacity(0.35)
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("\(Int(size.width.rounded())) × \(Int(size.height.rounded()))")
                    .font(.caption.monospacedDigit())
            }
            .padding(8)
            .background(.thinMaterial, in: .rect(cornerRadius: 8))
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: {
            size = $0
        }
        .border(color)
    }
}
