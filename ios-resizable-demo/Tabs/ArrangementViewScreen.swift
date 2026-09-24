import Foundation
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

// MARK: - Options

/// Form 上で Picker として一律に扱えるようにするための共通プロトコル。
private protocol ArrangementOption: CaseIterable, Hashable, Identifiable where AllCases: RandomAccessCollection {
    var label: String { get }
}

private enum StyleOption: String, ArrangementOption {
    case automatic
    case overlay
    case split
    case custom

    var id: Self { self }

    var label: String {
        switch self {
        case .automatic: "automatic"
        case .overlay: "overlay"
        case .split: "split"
        case .custom: "custom (PiP)"
        }
    }

    /// `.axes(_:)` を持つ組み込みスタイルかどうか。
    var supportsAxes: Bool {
        self == .overlay || self == .split
    }

    /// ペインごとに指定できる modifier があるスタイルかどうか。
    /// overlay は overlayArrangementEdge、split は splitArrangement 系を持つ。
    var hasPaneOptions: Bool {
        self == .overlay || self == .split
    }
}

private enum AxesOption: String, ArrangementOption {
    case unset
    case horizontal
    case vertical
    case both

    var id: Self { self }

    var label: String {
        switch self {
        case .unset: "指定しない"
        case .horizontal: "horizontal"
        case .vertical: "vertical"
        case .both: "horizontal + vertical"
        }
    }

    /// `nil` のときは `.axes(_:)` 自体を適用しない。
    var axes: Axis.Set? {
        switch self {
        case .unset: nil
        case .horizontal: .horizontal
        case .vertical: .vertical
        case .both: [.horizontal, .vertical]
        }
    }

    var code: String? {
        switch self {
        case .unset: nil
        case .horizontal: ".horizontal"
        case .vertical: ".vertical"
        case .both: "[.horizontal, .vertical]"
        }
    }
}

private enum PaneOption: String, ArrangementOption {
    case primary
    case secondary

    var id: Self { self }

    var label: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        }
    }
}

private enum HorizontalEdgeOption: String, ArrangementOption {
    case unset
    case leading
    case trailing

    var id: Self { self }

    var label: String {
        switch self {
        case .unset: "nil"
        case .leading: "leading"
        case .trailing: "trailing"
        }
    }

    var edge: HorizontalEdge? {
        switch self {
        case .unset: nil
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    var code: String? {
        edge == nil ? nil : ".\(rawValue)"
    }
}

private enum VerticalEdgeOption: String, ArrangementOption {
    case unset
    case top
    case bottom

    var id: Self { self }

    var label: String {
        switch self {
        case .unset: "nil"
        case .top: "top"
        case .bottom: "bottom"
        }
    }

    var edge: VerticalEdge? {
        switch self {
        case .unset: nil
        case .top: .top
        case .bottom: .bottom
        }
    }

    var code: String? {
        edge == nil ? nil : ".\(rawValue)"
    }
}

/// split レイアウトでのサイズ指定に使う modifier の選択。
/// 各 modifier は同時に指定すると解釈が曖昧になるため排他にしている。
private enum SplitSizingOption: String, ArrangementOption {
    case automatic
    case ratio
    case ratioRange
    case size
    case fixed

    var id: Self { self }

    var label: String {
        switch self {
        case .automatic: "指定しない"
        case .ratio: "LayoutRatio(_:)"
        case .ratioRange: "LayoutRatio(min/ideal/max)"
        case .size: "LayoutSize(min/ideal/max)"
        case .fixed: "FixedLayoutSize"
        }
    }
}

// MARK: - Pane configuration

/// primary / secondary いずれかのペインに適用するパラメーター一式。
private struct PaneConfig {
    // overlayArrangementEdge(_:)
    var horizontalEdge: HorizontalEdgeOption = .unset
    var verticalEdge: VerticalEdgeOption = .unset

    var sizing: SplitSizingOption = .automatic

    // splitArrangementLayoutRatio(_:)
    var ratio: CGFloat = 0.3

    // splitArrangementLayoutRatio(minHorizontal:...maxVertical:)
    var minHorizontalRatio: CGFloat? = 0.2
    var idealHorizontalRatio: CGFloat? = 0.3
    var maxHorizontalRatio: CGFloat? = 0.5
    var minVerticalRatio: CGFloat? = nil
    var idealVerticalRatio: CGFloat? = 0.4
    var maxVerticalRatio: CGFloat? = nil

    // splitArrangementLayoutSize(minWidth:...maxHeight:)
    var minWidth: CGFloat? = 120
    var idealWidth: CGFloat? = 200
    var maxWidth: CGFloat? = 320
    var minHeight: CGFloat? = nil
    var idealHeight: CGFloat? = 180
    var maxHeight: CGFloat? = nil

    // splitArrangementFixedLayoutSize(horizontal:vertical:)
    var fixedHorizontal = true
    var fixedVertical = true

    /// split のサイズ決定順に影響する。値が大きいペインから先にサイズが決まる。
    var layoutPriority: Double = 0
}

/// `PaneConfig` の内容をペインの中身へ適用する。
///
/// すべての modifier を無条件に適用し、未指定は `nil` / `false` を渡すことで表現している。
/// これにより選択を切り替えてもビューの型が変わらず、ペインの状態がリセットされない。
@available(iOS 27.1, *)
private struct ArrangementPaneModifier: ViewModifier {
    let config: PaneConfig

    func body(content: Content) -> some View {
        content
            // overlay が横並びに切り替わったときに寄せる辺。
            .overlayArrangementEdge(config.horizontalEdge.edge)
            // overlay が縦並びに切り替わったときに寄せる辺。
            .overlayArrangementEdge(config.verticalEdge.edge)
            .splitArrangementLayoutRatio(config.sizing == .ratio ? config.ratio : nil)
            .splitArrangementLayoutRatio(
                minHorizontal: config.sizing == .ratioRange ? config.minHorizontalRatio : nil,
                idealHorizontal: config.sizing == .ratioRange ? config.idealHorizontalRatio : nil,
                maxHorizontal: config.sizing == .ratioRange ? config.maxHorizontalRatio : nil,
                minVertical: config.sizing == .ratioRange ? config.minVerticalRatio : nil,
                idealVertical: config.sizing == .ratioRange ? config.idealVerticalRatio : nil,
                maxVertical: config.sizing == .ratioRange ? config.maxVerticalRatio : nil
            )
            .splitArrangementLayoutSize(
                minWidth: config.sizing == .size ? config.minWidth : nil,
                idealWidth: config.sizing == .size ? config.idealWidth : nil,
                maxWidth: config.sizing == .size ? config.maxWidth : nil,
                minHeight: config.sizing == .size ? config.minHeight : nil,
                idealHeight: config.sizing == .size ? config.idealHeight : nil,
                maxHeight: config.sizing == .size ? config.maxHeight : nil
            )
            .splitArrangementFixedLayoutSize(
                horizontal: config.sizing == .fixed && config.fixedHorizontal,
                vertical: config.sizing == .fixed && config.fixedVertical
            )
            .layoutPriority(config.layoutPriority)
    }
}

// MARK: - Custom style

/// `ArrangementViewStyle` / `ArrangementViewStyleConfiguration` の自作例。
/// secondary を全面に敷き、primary を右下の小窓として重ねる。
@available(iOS 27.1, *)
private struct PictureInPictureArrangementViewStyle: ArrangementViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .bottomTrailing) {
            configuration.secondary
            configuration.primary
                .frame(width: 150, height: 110)
                .clipShape(.rect(cornerRadius: 12))
                .shadow(radius: 6)
                .padding(16)
        }
    }
}

// MARK: - Demo

@available(iOS 27.1, *)
private struct ArrangementDemoView: View {
    @State private var style: StyleOption = .split
    @State private var axes: AxesOption = .unset
    @State private var editingPane: PaneOption = .primary
    @State private var primary = PaneConfig()
    @State private var secondary = PaneConfig()
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
                        // sheet 表示中も背後の ArrangementView が見えるよう小さめの detent も用意する。
                        .presentationDetents([.height(320), .medium, .large])
                }
        }
    }

    // MARK: Arrangement

    @ViewBuilder
    private var arrangement: some View {
        let base = ArrangementView {
            ColorPanel(title: "Primary", color: .blue)
                .modifier(ArrangementPaneModifier(config: primary))
        } secondary: {
            ColorPanel(title: "Secondary", color: .orange)
                .modifier(ArrangementPaneModifier(config: secondary))
        }

        switch style {
        case .automatic:
            base.arrangementViewStyle(.automatic)
        case .overlay:
            base.arrangementViewStyle(overlayStyle)
        case .split:
            base.arrangementViewStyle(splitStyle)
        case .custom:
            base.arrangementViewStyle(PictureInPictureArrangementViewStyle())
        }
    }

    private var overlayStyle: OverlayArrangementViewStyle {
        let style = OverlayArrangementViewStyle()
        guard let axes = axes.axes else { return style }
        return style.axes(axes)
    }

    private var splitStyle: SplitArrangementViewStyle {
        let style = SplitArrangementViewStyle()
        guard let axes = axes.axes else { return style }
        return style.axes(axes)
    }

    // MARK: Controls

    private var controls: some View {
        NavigationStack {
            Form {
                Section("arrangementViewStyle") {
                    optionPicker("style", selection: $style)
                    optionPicker("axes", selection: $axes)
                        .disabled(!style.supportsAxes)
                    if !style.supportsAxes {
                        Text("axes は overlay / split スタイルのみ指定できます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // ペインごとの設定を持たないスタイルでは選択セグメントも隠す。
                if style.hasPaneOptions {
                    Section {
                        Picker("編集するペイン", selection: $editingPane) {
                            ForEach(PaneOption.allCases) { pane in
                                Text(pane.label).tag(pane)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    paneSections(editedConfig)
                }

                Section("適用中のコード") {
                    Text(appliedCode)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isConfigPresented = false }
                }
            }
        }
    }

    private var editedConfig: Binding<PaneConfig> {
        editingPane == .primary ? $primary : $secondary
    }

    @ViewBuilder
    private func paneSections(_ config: Binding<PaneConfig>) -> some View {
        // overlayArrangementEdge は overlay スタイル以外では効果がないため隠す。
        if style == .overlay {
            Section("overlayArrangementEdge") {
                optionPicker("horizontal edge", selection: config.horizontalEdge)
                optionPicker("vertical edge", selection: config.verticalEdge)
            }
        }

        // splitArrangement 系は split スタイル以外では効果がないため隠す。
        if style == .split {
            splitSections(config)
        }
    }

    @ViewBuilder
    private func splitSections(_ config: Binding<PaneConfig>) -> some View {
        Section("split のサイズ指定") {
            optionPicker("modifier", selection: config.sizing)

            switch config.sizing.wrappedValue {
            case .automatic:
                Text("ペイン側からサイズを指定しません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .ratio:
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("ratio")
                        Spacer()
                        Text(ratioText(config.ratio.wrappedValue))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    Slider(value: config.ratio, in: 0...1)
                }

            case .ratioRange:
                optionalSlider("minHorizontal", value: config.minHorizontalRatio, default: 0.2, range: 0...1, decimals: 2)
                optionalSlider("idealHorizontal", value: config.idealHorizontalRatio, default: 0.3, range: 0...1, decimals: 2)
                optionalSlider("maxHorizontal", value: config.maxHorizontalRatio, default: 0.5, range: 0...1, decimals: 2)
                optionalSlider("minVertical", value: config.minVerticalRatio, default: 0.2, range: 0...1, decimals: 2)
                optionalSlider("idealVertical", value: config.idealVerticalRatio, default: 0.4, range: 0...1, decimals: 2)
                optionalSlider("maxVertical", value: config.maxVerticalRatio, default: 0.6, range: 0...1, decimals: 2)

            case .size:
                optionalSlider("minWidth", value: config.minWidth, default: 120, range: 0...600, decimals: 0)
                optionalSlider("idealWidth", value: config.idealWidth, default: 200, range: 0...600, decimals: 0)
                optionalSlider("maxWidth", value: config.maxWidth, default: 320, range: 0...600, decimals: 0)
                optionalSlider("minHeight", value: config.minHeight, default: 100, range: 0...600, decimals: 0)
                optionalSlider("idealHeight", value: config.idealHeight, default: 180, range: 0...600, decimals: 0)
                optionalSlider("maxHeight", value: config.maxHeight, default: 300, range: 0...600, decimals: 0)

            case .fixed:
                Toggle("horizontal", isOn: config.fixedHorizontal)
                Toggle("vertical", isOn: config.fixedVertical)
            }
        }

        Section("layoutPriority") {
            Stepper(value: config.layoutPriority, in: -2...2, step: 1) {
                HStack {
                    Text("layoutPriority")
                    Spacer()
                    Text("\(Int(config.layoutPriority.wrappedValue))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            Text("split では優先度の高いペインから先にサイズが決まります。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func optionPicker<Option: ArrangementOption>(
        _ title: String,
        selection: Binding<Option>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(Option.allCases) { option in
                Text(option.label).tag(option)
            }
        }
    }

    /// `nil` を取り得るパラメーターを「Toggle で有効化 + Slider で値指定」として扱う。
    @ViewBuilder
    private func optionalSlider(
        _ title: String,
        value: Binding<CGFloat?>,
        default defaultValue: CGFloat,
        range: ClosedRange<CGFloat>,
        decimals: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { value.wrappedValue != nil },
                set: { value.wrappedValue = $0 ? defaultValue : nil }
            )) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(value.wrappedValue.map { String(format: "%.\(decimals)f", $0) } ?? "nil")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            if let current = value.wrappedValue {
                Slider(
                    value: Binding(get: { current }, set: { value.wrappedValue = $0 }),
                    in: range
                )
            }
        }
    }

    // MARK: Generated code

    private var appliedCode: String {
        var lines = ["ArrangementView {"]
        lines.append(paneCode("Primary", primary))
        lines.append("} secondary: {")
        lines.append(paneCode("Secondary", secondary))
        lines.append("}")
        lines.append(".arrangementViewStyle(\(styleCode))")
        return lines.joined(separator: "\n")
    }

    private var styleCode: String {
        switch style {
        case .automatic:
            ".automatic"
        case .overlay:
            axes.code.map { ".overlay.axes(\($0))" } ?? ".overlay"
        case .split:
            axes.code.map { ".split.axes(\($0))" } ?? ".split"
        case .custom:
            "PictureInPictureArrangementViewStyle()"
        }
    }

    private func paneCode(_ name: String, _ config: PaneConfig) -> String {
        var lines = ["    \(name)()"]

        // 設定 UI と揃えて、overlay スタイルのときだけ edge を載せる。
        if style == .overlay {
            if let code = config.horizontalEdge.code {
                lines.append("        .overlayArrangementEdge(\(code))")
            }
            if let code = config.verticalEdge.code {
                lines.append("        .overlayArrangementEdge(\(code))")
            }
        }

        // 設定 UI と揃えて、split スタイルのときだけサイズ指定を載せる。
        switch style == .split ? config.sizing : .automatic {
        case .automatic:
            break

        case .ratio:
            lines.append("        .splitArrangementLayoutRatio(\(ratioText(config.ratio)))")

        case .ratioRange:
            let arguments = argumentList([
                ("minHorizontal", config.minHorizontalRatio, 2),
                ("idealHorizontal", config.idealHorizontalRatio, 2),
                ("maxHorizontal", config.maxHorizontalRatio, 2),
                ("minVertical", config.minVerticalRatio, 2),
                ("idealVertical", config.idealVerticalRatio, 2),
                ("maxVertical", config.maxVerticalRatio, 2)
            ])
            lines.append("        .splitArrangementLayoutRatio(\(arguments))")

        case .size:
            let arguments = argumentList([
                ("minWidth", config.minWidth, 0),
                ("idealWidth", config.idealWidth, 0),
                ("maxWidth", config.maxWidth, 0),
                ("minHeight", config.minHeight, 0),
                ("idealHeight", config.idealHeight, 0),
                ("maxHeight", config.maxHeight, 0)
            ])
            lines.append("        .splitArrangementLayoutSize(\(arguments))")

        case .fixed:
            lines.append(
                "        .splitArrangementFixedLayoutSize("
                + "horizontal: \(config.fixedHorizontal), vertical: \(config.fixedVertical))"
            )
        }

        if style == .split, config.layoutPriority != 0 {
            lines.append("        .layoutPriority(\(Int(config.layoutPriority)))")
        }

        return lines.joined(separator: "\n")
    }

    /// `nil` の引数は省略した形でコードを組み立てる。
    private func argumentList(_ arguments: [(String, CGFloat?, Int)]) -> String {
        arguments
            .compactMap { name, value, decimals in
                value.map { "\(name): \(String(format: "%.\(decimals)f", $0))" }
            }
            .joined(separator: ", ")
    }

    private func ratioText(_ value: CGFloat) -> String {
        String(format: "%.2f", value)
    }
}

// MARK: - Panel

@available(iOS 27.1, *)
private struct ColorPanel: View {
    let title: String
    let color: Color

    /// split arrangement 内でどちらの軸に並べられているか。split 外では nil。
    @Environment(\.splitArrangementAxis) private var splitAxis
    /// overlay arrangement 内での重なり順。値が大きいほど前面。
    @Environment(\.overlayArrangementZIndex) private var overlayZIndex

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
                Text("splitAxis: \(splitAxisText)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                Text("overlayZIndex: \(overlayZIndex)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
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

    private var splitAxisText: String {
        switch splitAxis {
        case .horizontal: "horizontal"
        case .vertical: "vertical"
        case nil: "nil"
        }
    }
}
