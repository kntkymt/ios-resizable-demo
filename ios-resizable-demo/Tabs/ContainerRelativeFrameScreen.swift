import SwiftUI

/// 画面全体に広がる ScrollView の中に幅 600 の LazyVStack をセンター揃えで置いたとき、
/// その中の containerRelativeFrame が 600 を無視して ScrollView 全体の幅まで広がるかを検証する画面。
///
/// 検証結果 (iPadOS 27 / iPad Pro 13-inch, ウィンドウ幅 1032pt):
/// - 現在の構成(幅 600 の外側に .frame(maxWidth: .infinity) を付けてコンテンツ幅を全幅にした状態)では、
///   幅 600 の中の containerRelativeFrame は 1032(ScrollView 全幅)に広がり、600 の帯をはみ出して描画される。
/// - .frame(maxWidth: .infinity) を付けない場合は 600 のままだった。縦 ScrollView はクロス軸方向に
///   コンテンツ幅までしか広がらず(UIScrollView の frame が実測で 600 × 1376)、コンテナ幅も 600 になるため。
/// - コンテンツ幅が 600 の構成でも「起動時から」ScrollView 直下に containerRelativeFrame を持つビューが
///   存在すると、初期レイアウトでコンテンツ幅がビューポート幅 (1032) に確定し、幅 600 の中の値も 1032 になる。
///   一方、実行時に Toggle で直下ビューを追加しても 600 のまま変わらない(初期レイアウトで決まった
///   ScrollView 幅 = コンテナ幅が固定点として維持されるヒステリシスがある)。
/// - なお containerRelativeFrame を .padding で包んで ScrollView 直下に置くと
///   「コンテナ幅 = コンテンツ幅 = コンテナ幅 + padding」の循環でレイアウトが無限ループしハングする。
struct ContainerRelativeFrameScreen: View {
    @State private var showsDirectRow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    MeasuredRow(title: ".frame(maxWidth: .infinity)", color: .blue) {
                        $0.frame(maxWidth: .infinity)
                    }

                    MeasuredRow(title: ".containerRelativeFrame(.horizontal)", color: .red) {
                        $0.containerRelativeFrame(.horizontal)
                    }

                    MeasuredRow(title: ".containerRelativeFrame(.horizontal) { $0 * 0.5 }", color: .orange) {
                        $0.containerRelativeFrame(.horizontal) { length, _ in
                            length * 0.5
                        }
                    }
                }
                .frame(width: 600)
                .background(.green.opacity(0.15))
                // コンテンツ自体は 600 のまま、ScrollView のコンテンツ幅を全幅に広げる。
                .frame(maxWidth: .infinity)

                // 比較用: Lazy でない VStack を幅 600 にした場合。
                VStack(spacing: 16) {
                    MeasuredRow(title: "in plain VStack: .containerRelativeFrame(.horizontal)", color: .purple) {
                        $0.containerRelativeFrame(.horizontal)
                    }
                }
                .frame(width: 600)
                .background(.gray.opacity(0.15))
                .frame(maxWidth: .infinity)

                // ScrollView 直下に置くとコンテンツ幅がビューポート幅まで広がり、
                // 上の幅 600 内の containerRelativeFrame の解決値も変わる。
                if showsDirectRow {
                    MeasuredRow(title: "direct in ScrollView: .containerRelativeFrame(.horizontal)", color: .teal) {
                        $0.containerRelativeFrame(.horizontal)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Toggle("ScrollView 直下に containerRelativeFrame の行を置く", isOn: $showsDirectRow)
                    .padding()
                    .background(.bar)
            }
            .navigationTitle("containerRelativeFrame")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 指定されたモディファイアを適用した行を描画し、実測幅をラベル表示する。
private struct MeasuredRow<Modified: View>: View {
    var title: String
    var color: Color
    var modifier: (AnyView) -> Modified

    @State private var measuredWidth: CGFloat = 0

    var body: some View {
        modifier(
            AnyView(
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption.monospaced())
                    Text("width: \(String(format: "%.1f", measuredWidth))")
                        .font(.callout.monospaced().bold())
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            )
        )
        .background(color.opacity(0.3))
        // モディファイア適用後の最終的な幅を計測する。
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            measuredWidth = width
        }
    }
}
