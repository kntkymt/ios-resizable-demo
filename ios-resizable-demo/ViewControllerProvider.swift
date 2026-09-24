import Combine
import SwiftUI
import UIKit

// SwiftUI の中から UIKit の UIViewController を直接操作するための汎用コンポーネント。
// content にアンカーとなる UIViewController を渡すので、任意のビューから present などを呼べる。
//
// 使い方:
//     ViewControllerProvider { controller in
//         Button("Present") {
//             controller?.present(UIHostingController(rootView: ...), animated: true)
//         }
//     }
//
// controller は content の .background に埋め込まれた空の VC で、
// view は content と同じフレームになるため popover の sourceView にそのまま使える。
// Attacher がビュー階層に取り付けられるまでの初回描画では nil が渡る。
struct ViewControllerProvider<Content: View>: View {
    @ViewBuilder let content: (UIViewController?) -> Content

    @StateObject private var holder = ViewControllerHolder()

    var body: some View {
        content(holder.viewController)
            .background(ViewControllerAttacher(holder: holder))
    }
}

private final class ViewControllerHolder: ObservableObject {
    // VC の所有者は SwiftUI(Attacher)側なので、weak で保持する。
    // Attacher が破棄されれば自動で nil に戻る。
    // (@Published は weak と併用できないため、手動で objectWillChange を送る)
    weak var viewController: UIViewController? {
        willSet {
            if newValue !== viewController {
                objectWillChange.send()
            }
        }
    }
}

private struct ViewControllerAttacher: UIViewControllerRepresentable {
    let holder: ViewControllerHolder

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard holder.viewController !== uiViewController else { return }

        // ビュー更新中に @Published を変更できないため、次のランループで代入する。
        DispatchQueue.main.async {
            holder.viewController = uiViewController
        }
    }
}
