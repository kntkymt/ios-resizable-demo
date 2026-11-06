import SwiftUI

// `canImport(SwiftUI, _version: 8.0.85)` は iOS 27.1 SDK (Xcode 27.1) 以上で真になる。
// Xcode 27.0 (iOS 27.0 SDK) でもビルドできるよう、27.1 で追加された API だけこの条件で分けている。
//
// この画面では 5 種類のツールバーアイテムを置き、それぞれに独立して
// ToolbarContent の modifier (placement / visibilityPriority / sharedBackgroundVisibility /
// contentMarginsRemoved / axisBehavior) を切り替えて挙動を確認できる。
// バー全体に効く View modifier (minimization / vertical behavior / compression) も同じ画面で切り替える。
// 検索フィールド (.searchable / principal に置いたカスタム / バー下に浮かせたカスタム) も同じ画面で切り替える。

@available(iOS 27.0, *)
struct ToolbarScreen: View {
    @State private var bar = ToolbarBarConfig()
    @State private var iconItem = ToolbarItemConfig(placement: .topBarTrailing)
    @State private var editItem = ToolbarItemConfig(placement: .topBarTrailing)
    @State private var overflowMenu = ToolbarItemConfig(placement: .automatic)
    @State private var groupItem = ToolbarItemConfig(placement: .topBarTrailing)
    @State private var customItem = ToolbarItemConfig(placement: .topBarLeading)
    @State private var selectedItem: DemoItem = .icon

    @State private var search = SearchFieldConfig()
    @State private var searchText = ""
    @State private var barContentWidth: CGFloat = 0
    @FocusState private var isSearchFieldFocused: Bool

    @State private var tapLog = "(none)"

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            searchContent
                // custom in toolbar 時は .principal が優先されるため、タイトルは表示されない。
                .navigationTitle("Toolbar")
                .navigationBarTitleDisplayMode(bar.titleDisplayMode.value)
                .toolbar {
                    toolbarItems
                }
                // minimization 系は 27.0 から。scroll でバーが縮む挙動を制御する。
                .toolbarMinimizationBehavior(bar.minimizationBehavior.value, for: .navigationBar)
                .toolbarMinimizationSafeAreaAdjustment(bar.minimizationSafeAreaAdjustment.value, for: .navigationBar)
                .toolbarMinimizationRestoration(bar.minimizationRestoration.value, for: .navigationBar)
                .modifier(VerticalBarModifiers(bar: bar))
        }
    }

    // MARK: - Search field

    @ViewBuilder
    private var searchContent: some View {
        switch search.type {
        case .none, .customInToolbar:
            settingsList

        case .searchable:
            settingsList
                .searchable(text: $searchText, prompt: "Search rows")

        case .customFloating:
            settingsList
                // ナビゲーションバーの下に検索バーを浮かせる。
                // safeAreaInset なので List のスクロール領域はその分だけ縮み、
                // 検索バーはスクロールしても固定されたままになる。
                .safeAreaInset(edge: .top) {
                    customSearchField
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
        }
    }

    private var customSearchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search rows", text: $searchText)
                .focused($isSearchFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.fill.tertiary, in: .capsule)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // 0. principal に置いたカスタム検索フィールド
        // principal にアイテムがあるバーはスクロールで自動的にミニマイズされるので、
        // 常に表示しておきたいときは .toolbarMinimizationBehavior を .never にする。
        if search.type == .customInToolbar {
            ToolbarItem(placement: .principal) {
                customSearchField
                    // ツールバーはアイテムに幅を提案せず固有サイズをそのまま使うため、
                    // maxWidth: .infinity では広がらない。空きスペースぶんの幅を明示的に指定する。
                    .frame(width: max(0, barContentWidth - search.reservedWidth))
            }
        }

        // 1. アイコンだけのボタン
        // Image ではなく Label + .iconOnly にしておくと、幅不足で「…」メニューへ畳まれたときに
        // メニュー側ではタイトル (Share) が表示される。
        if iconItem.isVisible {
            if let sizing = iconItem.spacerBefore.sizing {
                ToolbarSpacer(sizing, placement: iconItem.placement.value)
            }
            ToolbarItem(placement: iconItem.placement.value) {
                Button {
                    tapLog = "Icon"
                } label: {
                    Label {
                        Text("Share")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .toolbarItemConfiguration(iconItem)
        }

        // 2. 「編集」と文字のボタン
        if editItem.isVisible {
            if let sizing = editItem.spacerBefore.sizing {
                ToolbarSpacer(sizing, placement: editItem.placement.value)
            }
            ToolbarItem(placement: editItem.placement.value) {
                Button("編集") {
                    tapLog = "編集"
                }
            }
            .toolbarItemConfiguration(editItem)
        }

        // 3. ToolbarOverflowMenu
        // placement は指定できず、visibilityPriority で溢れたアイテムがこのメニューに畳まれる。
        if overflowMenu.isVisible {
            if let sizing = overflowMenu.spacerBefore.sizing {
                ToolbarSpacer(sizing, placement: .automatic)
            }
            ToolbarOverflowMenu {
                Button("Rename", systemImage: "pencil") {
                    tapLog = "Overflow: Rename"
                }
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    tapLog = "Overflow: Duplicate"
                }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    tapLog = "Overflow: Delete"
                }
            }
            .toolbarItemConfiguration(overflowMenu)
        }

        // 4. Group でアイコンのボタン二つ
        if groupItem.isVisible {
            if let sizing = groupItem.spacerBefore.sizing {
                ToolbarSpacer(sizing, placement: groupItem.placement.value)
            }
            ToolbarItemGroup(placement: groupItem.placement.value) {
                Button {
                    tapLog = "Group: Bold"
                } label: {
                    Label {
                        Text("Bold")
                    } icon: {
                        Image(systemName: "bold")
                    }
                    .labelStyle(.iconOnly)
                }
                Button {
                    tapLog = "Group: Italic"
                } label: {
                    Label {
                        Text("Italic")
                    } icon: {
                        Image(systemName: "italic")
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .toolbarItemConfiguration(groupItem)
        }

        // 5. カスタムの画像 + Text を HStack で置いたボタン
        if customItem.isVisible {
            if let sizing = customItem.spacerBefore.sizing {
                ToolbarSpacer(sizing, placement: customItem.placement.value)
            }
            ToolbarItem(placement: customItem.placement.value) {
                Button {
                    tapLog = "Custom"
                } label: {
                    HStack(spacing: 6) {
                        avatarImage
                        Text("Profile")
                    }
                }
            }
            .toolbarItemConfiguration(customItem)
        }
    }

    // SF Symbols ではない独自描画の画像。テンプレート扱いされないのでそのままの色で表示される。
    private var avatarImage: Image {
        let size = CGSize(width: 22, height: 22)
        return Image(size: size) { context in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(
                Path(ellipseIn: rect),
                with: .linearGradient(
                    Gradient(colors: [.orange, .pink]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            context.fill(
                Path(ellipseIn: rect.insetBy(dx: 7, dy: 7)),
                with: .color(.white)
            )
        }
    }

    // MARK: - Settings

    private var settingsList: some View {
        List {
            Section("Info") {
                infoRow("last tap", tapLog)
                infoRow("horizontalSizeClass", horizontalSizeClass.map { String(describing: $0) } ?? "nil")
                #if canImport(SwiftUI, _version: 8.0.85)
                if #available(iOS 27.1, *) {
                    ToolbarVerticalEdgeRow()
                }
                #endif
            }

            // 5 つのアイテムの設定は Segmented Picker で対象を切り替えて 1 つの Section に表示する。
            // 設定値自体はアイテムごとに独立して保持されるので、切り替えても失われない。
            ToolbarItemConfigSection(
                item: selectedItem,
                selection: $selectedItem,
                config: selectedItemConfig
            )

            Section("Search field") {
                optionPicker("type", selection: $search.type) { $0.title }
                if search.type == .customInToolbar {
                    // 他のツールバーアイテムと両端マージン・アイテム間ギャップのぶん。
                    // アイテムの表示状態に応じて調整する。
                    Stepper(value: $search.reservedWidth, in: 0...400, step: 10) {
                        infoRow("reserved width", "\(Int(search.reservedWidth))")
                    }
                }
                infoRow("search text", searchText.isEmpty ? "(empty)" : searchText)
            }

            Section("Bar (View modifiers)") {
                optionPicker(".navigationBarTitleDisplayMode", selection: $bar.titleDisplayMode)
                optionPicker(".toolbarMinimizationBehavior", selection: $bar.minimizationBehavior)
                optionPicker(".toolbarMinimizationSafeAreaAdjustment", selection: $bar.minimizationSafeAreaAdjustment)
                optionPicker(".toolbarMinimizationRestoration", selection: $bar.minimizationRestoration)
                verticalBarRows
            }

            // minimization の挙動を見るためにスクロールできる長さを確保する。
            // 検索フィールドの入力でこの行を絞り込む。
            Section("Scroll filler") {
                ForEach(filteredRows, id: \.self) { row in
                    Text(row)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if filteredRows.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        // ツールバー自体のサイズは直接測れないため、画面幅いっぱいの List で代用する。
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            barContentWidth = width
        }
    }

    private var filteredRows: [String] {
        let rows = (1...30).map { "Row \($0)" }
        return searchText.isEmpty
            ? rows
            : rows.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    @ViewBuilder
    private var verticalBarRows: some View {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            optionPicker(".toolbarVerticalBehavior", selection: $bar.verticalBehavior)
            optionPicker(".toolbarVerticalCompressionBehavior", selection: $bar.verticalCompressionBehavior)
        } else {
            unavailableRow(".toolbarVerticalBehavior", "requires iOS 27.1")
            unavailableRow(".toolbarVerticalCompressionBehavior", "requires iOS 27.1")
        }
        #else
        unavailableRow(".toolbarVerticalBehavior", "requires iOS 27.1 SDK")
        unavailableRow(".toolbarVerticalCompressionBehavior", "requires iOS 27.1 SDK")
        #endif
    }
}

@available(iOS 27.0, *)
extension ToolbarScreen {
    private var selectedItemConfig: Binding<ToolbarItemConfig> {
        switch selectedItem {
        case .icon: $iconItem
        case .edit: $editItem
        case .overflow: $overflowMenu
        case .group: $groupItem
        case .custom: $customItem
        }
    }
}

/// 設定対象として選べる 5 つのツールバーアイテム。
enum DemoItem: String, CaseIterable, Identifiable {
    case icon
    case edit
    case overflow
    case group
    case custom

    var id: String { rawValue }

    /// Segmented Picker 用の短いラベル。
    var shortTitle: String {
        switch self {
        case .icon: "Icon"
        case .edit: "編集"
        case .overflow: "Overflow"
        case .group: "Group"
        case .custom: "Custom"
        }
    }

    var title: String {
        switch self {
        case .icon: "1. Icon Button"
        case .edit: "2. 「編集」 Text Button"
        case .overflow: "3. ToolbarOverflowMenu"
        case .group: "4. ToolbarItemGroup (2 icons)"
        case .custom: "5. Custom Image + Text"
        }
    }

    // ToolbarOverflowMenu は placement を受け取らない。
    var supportsPlacement: Bool {
        self != .overflow
    }
}

// MARK: - Per-item configuration

/// ツールバーアイテム 1 つぶんの設定。各アイテムが独立にこの値を持つ。
struct ToolbarItemConfig {
    var isVisible = true
    var placement: Placement
    var visibilityPriority: VisibilityPriority = .automatic
    var sharedBackgroundVisibility: SharedBackgroundVisibility = .automatic
    var contentMarginsRemoved = false
    var axisBehavior: AxisBehavior = .automatic
    var spacerBefore: SpacerBefore = .none

    init(placement: Placement) {
        self.placement = placement
    }

    enum Placement: String, CaseIterable, Identifiable {
        case automatic
        case topBarLeading
        case topBarTrailing
        // 27.0 で追加。ミニマイズ時や Duo の縦バーでも末尾に固定される。
        case topBarPinnedTrailing
        case principal
        case bottomBar

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }

        @available(iOS 27.0, *)
        var value: ToolbarItemPlacement {
            switch self {
            case .automatic: .automatic
            case .topBarLeading: .topBarLeading
            case .topBarTrailing: .topBarTrailing
            case .topBarPinnedTrailing: .topBarPinnedTrailing
            case .principal: .principal
            case .bottomBar: .bottomBar
            }
        }
    }

    /// 幅が足りないときにオーバーフローメニューへ畳まれる優先度。low が先に畳まれ、high は最後まで残る。
    enum VisibilityPriority: String, CaseIterable, Identifiable {
        case automatic
        case low
        case high

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }

        @available(iOS 27.0, *)
        var value: ToolbarItemVisibilityPriority {
            switch self {
            case .automatic: .automatic
            case .low: .low
            case .high: .high
            }
        }
    }

    /// 隣接アイテムと Liquid Glass の背景を共有するか。hidden にすると独立したカプセルになる。
    enum SharedBackgroundVisibility: String, CaseIterable, Identifiable {
        case automatic
        case visible
        case hidden

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }

        var value: Visibility {
            switch self {
            case .automatic: .automatic
            case .visible: .visible
            case .hidden: .hidden
            }
        }
    }

    /// このアイテムの手前に挟む ToolbarSpacer。
    /// 同じ placement のアイテムは既定で 1 つの Liquid Glass 背景を共有するため、
    /// fixed を挟むとそこでカプセルが分かれる。flexible は空きスペースを吸収して両側へ押し広げる。
    enum SpacerBefore: String, CaseIterable, Identifiable {
        case none
        case fixed
        case flexible

        var id: String { rawValue }

        @available(iOS 26.0, *)
        var sizing: SpacerSizing? {
            switch self {
            case .none: nil
            case .fixed: .fixed
            case .flexible: .flexible
            }
        }
    }

    /// ツールバーが縦 (画面の左右端) に配置されるときにアイテムがどう振る舞うか。
    /// horizontalOnly は横バーにだけ残り、verticalPreferred は縦バーを優先する。
    enum AxisBehavior: String, CaseIterable, Identifiable {
        case automatic
        case horizontalOnly
        case verticalPreferred

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }
    }
}

#if canImport(SwiftUI, _version: 8.0.85)
@available(iOS 27.1, *)
extension ToolbarItemConfig.AxisBehavior {
    var value: ToolbarItemAxisBehavior {
        switch self {
        case .automatic: .automatic
        case .horizontalOnly: .horizontalOnly
        case .verticalPreferred: .verticalPreferred
        }
    }
}
#endif

@available(iOS 27.0, *)
extension ToolbarContent {
    /// ToolbarItemConfig の内容をまとめて適用する。
    /// axisBehavior だけは 27.1 からなので、ToolbarContentBuilder の buildLimitedAvailability で分岐する。
    @MainActor
    @ToolbarContentBuilder
    func toolbarItemConfiguration(_ config: ToolbarItemConfig) -> some ToolbarContent {
        let base = self
            .visibilityPriority(config.visibilityPriority.value)
            .sharedBackgroundVisibility(config.sharedBackgroundVisibility.value)
            .contentMarginsRemoved(config.contentMarginsRemoved)

        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            base.axisBehavior(config.axisBehavior.value)
        } else {
            base
        }
        #else
        base
        #endif
    }
}

@available(iOS 27.0, *)
private struct ToolbarItemConfigSection: View {
    let item: DemoItem
    @Binding var selection: DemoItem
    @Binding var config: ToolbarItemConfig

    var body: some View {
        Section {
            Picker("Item", selection: $selection) {
                ForEach(DemoItem.allCases) { item in
                    Text(item.shortTitle).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

            Toggle("visible", isOn: $config.isVisible)
            if item.supportsPlacement {
                optionPicker("placement", selection: $config.placement)
            }
            optionPicker(".visibilityPriority", selection: $config.visibilityPriority)
            optionPicker(".sharedBackgroundVisibility", selection: $config.sharedBackgroundVisibility)
            Toggle(".contentMarginsRemoved", isOn: $config.contentMarginsRemoved)
            optionPicker("ToolbarSpacer (before)", selection: $config.spacerBefore)
            axisBehaviorRow
        } header: {
            Text("Item: \(item.title)")
        }
    }

    @ViewBuilder
    private var axisBehaviorRow: some View {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            optionPicker(".axisBehavior", selection: $config.axisBehavior)
        } else {
            unavailableRow(".axisBehavior", "requires iOS 27.1")
        }
        #else
        unavailableRow(".axisBehavior", "requires iOS 27.1 SDK")
        #endif
    }
}

// MARK: - Search field configuration

struct SearchFieldConfig {
    var type: SearchFieldType = .none
    /// principal に置くときに、検索フィールド以外のアイテムとマージンのために空けておく幅。
    var reservedWidth: CGFloat = 150

    enum SearchFieldType: String, CaseIterable, Identifiable {
        case none
        case searchable
        case customInToolbar = "custom in toolbar"
        case customFloating = "custom floating"

        var id: String { rawValue }
        var title: String { rawValue }
    }
}

// MARK: - Bar-level configuration

struct ToolbarBarConfig {
    var titleDisplayMode: TitleDisplayModeOption = .automatic
    var minimizationBehavior: MinimizationBehavior = .automatic
    var minimizationSafeAreaAdjustment: MinimizationSafeAreaAdjustment = .automatic
    var minimizationRestoration: MinimizationRestoration = .automatic
    var verticalBehavior: VerticalBehavior = .automatic
    var verticalCompressionBehavior: VerticalCompressionBehavior = .automatic

    /// スクロールでバーをミニマイズするか、どの方向のスクロールで縮めるか。
    enum MinimizationBehavior: String, CaseIterable, Identifiable {
        case automatic
        case onScrollDown
        case onScrollUp
        case never

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }

        @available(iOS 27.0, *)
        var value: ToolbarMinimizationBehavior {
            switch self {
            case .automatic: .automatic
            case .onScrollDown: .onScrollDown
            case .onScrollUp: .onScrollUp
            case .never: .never
            }
        }
    }

    /// ミニマイズ時にコンテンツの safe area も合わせて縮めるか。
    enum MinimizationSafeAreaAdjustment: String, CaseIterable, Identifiable {
        case automatic
        case enabled
        case disabled

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }

        @available(iOS 27.0, *)
        var value: ToolbarMinimizationSafeAreaAdjustment {
            switch self {
            case .automatic: .automatic
            case .enabled: .enabled
            case .disabled: .disabled
            }
        }
    }

    /// ミニマイズからの復帰タイミング。atScrollEdge はスクロール端に達するまで戻らない。
    enum MinimizationRestoration: String, CaseIterable, Identifiable {
        case automatic
        case atScrollEdge

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }

        @available(iOS 27.0, *)
        var value: ToolbarMinimizationRestoration {
            switch self {
            case .automatic: .automatic
            case .atScrollEdge: .atScrollEdge
            }
        }
    }

    /// Duo のような環境でツールバーを縦 (左右端) に配置する挙動を無効化できる。
    enum VerticalBehavior: String, CaseIterable, Identifiable {
        case automatic
        case disabled

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }
    }

    /// 縦バーのスペースが足りないときにツールバーアイテムとタブバーのどちらを優先して残すか。
    enum VerticalCompressionBehavior: String, CaseIterable, Identifiable {
        case automatic
        case prefersToolbarItems
        case prefersTabBar

        var id: String { rawValue }
        var title: String { ".\(rawValue)" }
    }
}

#if canImport(SwiftUI, _version: 8.0.85)
@available(iOS 27.1, *)
extension ToolbarBarConfig.VerticalBehavior {
    var value: ToolbarVerticalBehavior {
        switch self {
        case .automatic: .automatic
        case .disabled: .disabled
        }
    }
}

@available(iOS 27.1, *)
extension ToolbarBarConfig.VerticalCompressionBehavior {
    var value: ToolbarVerticalCompressionBehavior {
        switch self {
        case .automatic: .automatic
        case .prefersToolbarItems: .prefersToolbarItems
        case .prefersTabBar: .prefersTabBar
        }
    }
}

@available(iOS 27.1, *)
private struct ToolbarVerticalEdgeRow: View {
    // ツールバーが縦に配置されているとき、どちらの端にあるか。横配置なら nil。
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge

    var body: some View {
        infoRow("toolbarVerticalEdge", toolbarVerticalEdge.map { String(describing: $0) } ?? "nil (horizontal)")
    }
}
#endif

/// 27.1 の View modifier を、iOS 27.0 向けビルドでもコンパイル・実行できるように分離した ViewModifier。
@available(iOS 27.0, *)
private struct VerticalBarModifiers: ViewModifier {
    let bar: ToolbarBarConfig

    func body(content: Content) -> some View {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .toolbarVerticalBehavior(bar.verticalBehavior.value)
                .toolbarVerticalCompressionBehavior(bar.verticalCompressionBehavior.value)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

// MARK: - Shared rows

private func optionPicker<Option: CaseIterable & Identifiable & Hashable>(
    _ title: String,
    selection: Binding<Option>,
    titleFor: @escaping (Option) -> String
) -> some View where Option.AllCases: RandomAccessCollection {
    Picker(selection: selection) {
        ForEach(Option.allCases) { option in
            Text(titleFor(option)).tag(option)
        }
    } label: {
        Text(title)
            .font(.footnote.monospaced())
    }
}

private func optionPicker<Option: CaseIterable & Identifiable & Hashable & RawRepresentable>(
    _ title: String,
    selection: Binding<Option>
) -> some View where Option.AllCases: RandomAccessCollection, Option.RawValue == String {
    optionPicker(title, selection: selection) { option in
        // PresentationStylesScreen の TitleDisplayModeOption など、title を持たない既存 enum にも使えるよう rawValue を使う。
        ".\(option.rawValue)"
    }
}

private func infoRow(_ title: String, _ value: String) -> some View {
    HStack {
        Text(title)
            .font(.footnote.monospaced())
            .foregroundStyle(.secondary)
        Spacer()
        Text(value)
            .font(.footnote.monospaced())
            .multilineTextAlignment(.trailing)
    }
}

private func unavailableRow(_ title: String, _ reason: String) -> some View {
    infoRow(title, reason)
        .foregroundStyle(.tertiary)
}
