import SwiftUI

struct SearchableScreen: View {
    @State private var searchText = ""
    @State private var usesCustomSearchField = true
    @State private var barContentWidth: CGFloat = 0
    @FocusState private var isSearchFieldFocused: Bool

    // トレーリングのボタン群(2個)と両端マージン・アイテム間ギャップのぶん。
    private let toolbarReservedWidth: CGFloat = 150

    private let fruits = [
        "Apple", "Apricot", "Banana", "Blueberry", "Cherry",
        "Grape", "Kiwi", "Lemon", "Mango", "Melon",
        "Orange", "Peach", "Pear", "Pineapple", "Strawberry"
    ]

    private var filteredFruits: [String] {
        if searchText.isEmpty {
            fruits
        } else {
            fruits.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            if #available(iOS 27.0, *) {
                // principal にアイテムがあるバーはスクロールで自動的にミニマイズされるため、
                // 常に表示され続ける(sticky)ように無効化する。
                searchModeContent
                    .toolbarMinimizationBehavior(.never, for: .navigationBar)
            } else {
                searchModeContent
            }
        }
    }

    @ViewBuilder
    private var searchModeContent: some View {
        if usesCustomSearchField {
            fruitsList
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        customSearchField
                    }
                    trailingButtons
                }
        } else {
            fruitsList
                .searchable(text: $searchText, prompt: "Search fruits")
                .toolbar {
                    trailingButtons
                }
        }
    }

    private var fruitsList: some View {
        List {
            Section("Search Field") {
                Toggle("Use Custom Search Field", isOn: $usesCustomSearchField)
            }

            Section("Fruits") {
                ForEach(filteredFruits, id: \.self) { fruit in
                    Text(fruit)
                }
            }
        }
        .overlay {
            if filteredFruits.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        // ツールバー自体のサイズは直接測れないため、画面幅いっぱいの List で代用する。
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            barContentWidth = width
        }
        // カスタム時は .principal が優先されるため、タイトルは表示されない。
        .navigationTitle("Searchable Sample")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ToolbarContentBuilder
    private var trailingButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private var customSearchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search fruits", text: $searchText)
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
        // ツールバーはアイテムに幅を提案せず固有サイズをそのまま使うため、
        // maxWidth: .infinity では広がらない。空きスペースぶんの幅を明示的に指定する。
        .frame(width: max(0, barContentWidth - toolbarReservedWidth))
    }
}

#Preview {
    SearchableScreen()
}
