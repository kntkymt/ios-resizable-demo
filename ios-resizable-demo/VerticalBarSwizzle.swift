import Foundation
import ObjectiveC

// 縦バーの可否はシステム(ホスト)がディスク上のInfo.plistのUISupportsVerticalBarから決め、
// シーン設定のsystemProvidesVerticalBarsとしてアプリに送ってくる。
// アプリ側はこれを-[_UISceneBarPositionClientComponent _systemProvidesVerticalBars]で読むため、
// ここを差し替えて常にNOを返させる。
enum VerticalBarSwizzle {
    static func disableSystemProvidedVerticalBars() {
        let selector = NSSelectorFromString("_systemProvidesVerticalBars")
        guard let cls = NSClassFromString("_UISceneBarPositionClientComponent"),
              let method = class_getInstanceMethod(cls, selector) else {
            return
        }
        let block: @convention(block) (AnyObject) -> Bool = { _ in false }
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}
