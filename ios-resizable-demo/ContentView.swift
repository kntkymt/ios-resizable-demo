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
            Tab("Share", systemImage: "square.and.arrow.up") {
                ShareScreen()
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
        }
    }
}
