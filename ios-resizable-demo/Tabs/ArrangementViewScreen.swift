import SwiftUI

struct ArrangementViewScreen: View {
    var body: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                CounterView()
            } secondary: {
                CounterView()
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

struct CounterView: View {
    @State var count = 0

    var body: some View {
        Button {
            count += 1
        } label: {
            Text(count.description)
        }
    }
}
