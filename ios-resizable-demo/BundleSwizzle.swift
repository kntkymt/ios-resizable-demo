import Foundation
import ObjectiveC

// UIKitはUISupportsVerticalBarを起動時にNSBundle経由で読み取るため、
// NSBundleのInfo.plist読み取りメソッドをswizzleしてfalseを返すよう差し替える。
// App.initでは間に合わないため、main.swiftでMyApp.main()より前に呼ぶ。
extension Bundle {
    private static let supportsVerticalBarKey = "UISupportsVerticalBar"

    static func swizzleSupportsVerticalBar() {
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
        if self === Bundle.main, key == Bundle.supportsVerticalBarKey {
            return false
        }
        // swizzle済みのため、これは元のobject(forInfoDictionaryKey:)を呼び出す
        return swizzled_object(forInfoDictionaryKey: key)
    }

    @objc private var swizzled_infoDictionary: [String: Any]? {
        // swizzle済みのため、これは元のinfoDictionaryを呼び出す
        var info = swizzled_infoDictionary
        if self === Bundle.main {
            info?[Bundle.supportsVerticalBarKey] = false
        }
        return info
    }
}
