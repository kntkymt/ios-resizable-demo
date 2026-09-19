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
            Tab("Size Class", systemImage: "ruler") {
                SizeClassScreen()
            }
            Tab("CRF", systemImage: "arrow.left.and.right.square") {
                ContainerRelativeFrameScreen()
            }
            Tab("Layout", systemImage: "square") {
                ArrangementScreen()
            }
        }
    }
}

struct ArrangementScreen: View {
    @State var addnavigationTitle = true

    var content: some View {
        ZStack {
            Color.red

            Toggle("Add navigation title", isOn: $addnavigationTitle)
        }
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
