import SwiftUI

struct SearchableScreen: View {
    @State private var searchText = ""

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
            List {
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
            .navigationTitle("Searchable Sample")
            .searchable(text: $searchText, prompt: "Search fruits")
        }
    }
}
