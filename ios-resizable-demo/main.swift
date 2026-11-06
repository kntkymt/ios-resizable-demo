import SwiftUI

// App.initより前にUIKitがInfo.plistを読むため、@mainではなく
// ここでMyApp.main()より前にswizzleする。
//Bundle.swizzleSupportsVerticalBar()
//VerticalBarSwizzle.disableSystemProvidedVerticalBars()
MyApp.main()
