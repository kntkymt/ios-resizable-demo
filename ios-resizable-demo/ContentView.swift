import SwiftUI
import Playgrounds
import AppIntents

@main struct MyApp: App {
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
            Tab("Size Class", systemImage: "ruler") {
                SizeClassScreen()
            }
        }
    }
}
