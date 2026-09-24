import SwiftUI
import Playgrounds
import AppIntents

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Presentation Styles", systemImage: "rectangle.portrait.on.rectangle.portrait") {
                PresentationStylesScreen()
            }
            Tab("Parameters", systemImage: "ruler") {
                ParametersScreen()
            }
            Tab("Content Area", systemImage: "square.dashed") {
                ContentAreaScreen()
            }
            Tab("Arrangement View", systemImage: "rectangle.split.2x1") {
                ArrangementViewScreen()
            }
            Tab("Searchable", systemImage: "magnifyingglass", role: .search) {
                SearchableScreen()
            }
        }
    }
}
