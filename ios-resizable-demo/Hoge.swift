import SwiftUI

// UIKitがUIRequiresFullScreenを読み取る前に差し替える必要があるため、
// @mainではなくmain.swiftでUIApplicationMainの前にswizzleする。
// main.swiftのトップレベルは必ずメインスレッドで実行されるためassumeIsolatedで問題ない
//MainActor.assumeIsolated {
//    Bundle.swizzleRequiresFullScreen()
//}
//MyApp.main()
