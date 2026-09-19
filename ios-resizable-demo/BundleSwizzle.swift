import UIKit

// UIKitはUIRequiresFullScreenを起動時にNSBundle経由で読み取るため、
// NSBundleのInfo.plist読み取りメソッドをswizzleして
// iPhone(idiom == .phone)のときだけtrueを返すよう差し替える。
// UIKitが読み取る前に差し替える必要があるため、main.swiftでUIApplicationMainの前に呼ぶ。
extension Bundle {
    // swizzleRequiresFullScreen()で一度だけ書き込み、以降は読み取り専用なのでunsafeでも安全
    private nonisolated(unsafe) static var requiresFullScreen = false

    @MainActor
    static func swizzleRequiresFullScreen() {
        // UIDevice.currentは@MainActorのため、swizzledメソッド(任意スレッドから
        // 呼ばれる)内では読めない。登録時にここで一度だけ判定してキャッシュする。
        requiresFullScreen = UIDevice.current.userInterfaceIdiom == .phone

        let selectorPairs: [(original: Selector, swizzled: Selector)] = [
            (#selector(Bundle.object(forInfoDictionaryKey:)),
             #selector(Bundle.swizzled_object(forInfoDictionaryKey:))),
            (#selector(getter: Bundle.infoDictionary),
             #selector(getter: Bundle.swizzled_infoDictionary)),
        ]
        for pair in selectorPairs {
            guard let originalMethod = class_getInstanceMethod(Bundle.self, pair.original),
                  let swizzledMethod = class_getInstanceMethod(Bundle.self, pair.swizzled) else {
                continue
            }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc private func swizzled_object(forInfoDictionaryKey key: String) -> Any? {
        if self === Bundle.main, key == "UIRequiresFullScreen" {
            return Bundle.requiresFullScreen
        }
        // swizzle済みのため、これは元のobject(forInfoDictionaryKey:)を呼び出す
        return swizzled_object(forInfoDictionaryKey: key)
    }

    @objc private var swizzled_infoDictionary: [String: Any]? {
        // swizzle済みのため、これは元のinfoDictionaryを呼び出す
        var info = swizzled_infoDictionary
        if self === Bundle.main {
            info?["UIRequiresFullScreen"] = Bundle.requiresFullScreen
        }
        return info
    }
}
