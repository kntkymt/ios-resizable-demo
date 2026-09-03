# ios-resizable-demo

A sample app for comparing how various sharing / modal presentation APIs look and behave across iOS 26 → iOS 27 and Xcode 26 → Xcode 27.

The app has two tabs in a `TabView`:

- **Share** (`ShareScreen.swift`): demos for `UIActivityViewController` (UIKit), `ShareLink`, `.sheet`, `.popover`, and `.confirmationDialog`
- **Size Class** (`SizeClassScreen.swift`): shows the current horizontal / vertical size classes

## Environments compared

| Column | Built with | Running on |
| --- | --- | --- |
| Xcode26_ios18 | Xcode 26 | iOS 18.6 |
| Xcode26_ios26 | Xcode 26 | iOS 26.5 |
| Xcode26_ios27 | Xcode 26 | iOS 27 |
| Xcode27_ios27 | Xcode 27 | iOS 27 |

Note that there is no Xcode27_ios26 combination: it produces the same result as Xcode26_ios26, and in theory, behavior newly introduced in a newer SDK cannot take effect on an older OS that has already shipped.

Screenshots are located at `Resources/<environment>/<device configuration>/<method>.png`.

## Xcode27_ios27

| method | iphone_compact | iphone_regular_rotate | iphone_regular_resizable | ipad_compact | ipad_regular |
| --- | --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode27_ios27/iphone_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_resizable/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_regular/uiactivitycontroller.png" width="200"> |
| sharelink | <img src="Resources/xcode27_ios27/iphone_compact/sharelink.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/sharelink.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_resizable/sharelink.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_compact/sharelink.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_regular/sharelink.png" width="200"> |
| sheet | <img src="Resources/xcode27_ios27/iphone_compact/sheet.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/sheet.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_resizable/sheet.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_compact/sheet.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_regular/sheet.png" width="200"> |
| popover | <img src="Resources/xcode27_ios27/iphone_compact/popover.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/popover.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_resizable/popover.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_compact/popover.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_regular/popover.png" width="200"> |
| confirmationdialog | <img src="Resources/xcode27_ios27/iphone_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/confirmationdialog.png" width="200"> | <img src="Resources/xcode27_ios27/iphone_regular_resizable/confirmationdialog.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode27_ios27/ipad_regular/confirmationdialog.png" width="200"> |

### Findings

- The share sheet (UIKit/SwiftUI) displays as a bubble only on iPad regular; otherwise it displays as a sheet.
- `.sheet` displays as a full-screen sheet on iPhone regular; otherwise it displays as a half sheet.
- `popover` displays as a bubble on resizable regular and iPad regular; otherwise it displays as a sheet.
- `confirmationDialog` always displays as a bubble (since Liquid Glass).

In other words, the horizontal size class is not the only criterion for the display style; the device type and resizable environment are also taken into account.

Basically, there are no obvious style changes between iOS 26 and iOS 27, while iOS 18.6 looks completely different due to the Liquid Glass redesign introduced in iOS 26. See below for the details of each version.

<details>
<summary>Xcode26_ios27</summary>

| method | iphone_compact | iphone_regular_rotate | ipad_compact | ipad_regular |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios27/iphone_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_regular/uiactivitycontroller.png" width="200"> |
| sharelink | <img src="Resources/xcode26_ios27/iphone_compact/sharelink.png" width="200"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/sharelink.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_compact/sharelink.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_regular/sharelink.png" width="200"> |
| sheet | <img src="Resources/xcode26_ios27/iphone_compact/sheet.png" width="200"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/sheet.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_compact/sheet.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_regular/sheet.png" width="200"> |
| popover | <img src="Resources/xcode26_ios27/iphone_compact/popover.png" width="200"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/popover.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_compact/popover.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_regular/popover.png" width="200"> |
| confirmationdialog | <img src="Resources/xcode26_ios27/iphone_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios27/ipad_regular/confirmationdialog.png" width="200"> |

</details>

<details>
<summary>Xcode26_ios26</summary>

| method | iphone_compact | iphone_regular_rotate | ipad_compact | ipad_regular |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios26.5/iphone_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_regular/uiactivitycontroller.png" width="200"> |
| sharelink | <img src="Resources/xcode26_ios26.5/iphone_compact/sharelink.png" width="200"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/sharelink.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_compact/sharelink.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_regular/sharelink.png" width="200"> |
| sheet | <img src="Resources/xcode26_ios26.5/iphone_compact/sheet.png" width="200"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/sheet.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_compact/sheet.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_regular/sheet.png" width="200"> |
| popover | <img src="Resources/xcode26_ios26.5/iphone_compact/popover.png" width="200"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/popover.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_compact/popover.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_regular/popover.png" width="200"> |
| confirmationdialog | <img src="Resources/xcode26_ios26.5/iphone_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios26.5/ipad_regular/confirmationdialog.png" width="200"> |

</details>

<details>
<summary>Xcode26_ios18</summary>

| method | iphone_compact | iphone_regular_rotate | ipad_compact | ipad_regular |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios18.6/iphone_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_compact/uiactivitycontroller.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_regular/uiactivitycontroller.png" width="200"> |
| sharelink | <img src="Resources/xcode26_ios18.6/iphone_compact/sharelink.png" width="200"> | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/sharelink.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_compact/sharelink.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_regular/sharelink.png" width="200"> |
| sheet | <img src="Resources/xcode26_ios18.6/iphone_compact/sheet.png" width="200"> | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/sheet.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_compact/sheet.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_regular/sheet.png" width="200"> |
| popover | <img src="Resources/xcode26_ios18.6/iphone_compact/popover.png" width="200"> | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/popover.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_compact/popover.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_regular/popover.png" width="200"> |
| confirmationdialog | <img src="Resources/xcode26_ios18.6/iphone_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_compact/confirmationdialog.png" width="200"> | <img src="Resources/xcode26_ios18.6/ipad_regular/confirmationdialog.png" width="200"> |

</details>

---

# By device configuration

iOS 26 introduced the Liquid Glass redesign, so every method looks visually different between iOS 18.6 and iOS 26+. The notes below focus on layout / behavioral changes.

## iPhone (compact)

The only behavioral change is `confirmationDialog`: a bottom action sheet with a Cancel button in iOS 18.6 became a bubble anchored to the source button in iOS 26.

| method | Xcode26_ios18 | Xcode26_ios26 | Xcode26_ios27 | Xcode27_ios27 |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios18.6/iphone_compact/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_compact/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_compact/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_compact/uiactivitycontroller.png" width="250"> |
| sharelink | <img src="Resources/xcode26_ios18.6/iphone_compact/sharelink.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_compact/sharelink.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_compact/sharelink.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_compact/sharelink.png" width="250"> |
| sheet | <img src="Resources/xcode26_ios18.6/iphone_compact/sheet.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_compact/sheet.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_compact/sheet.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_compact/sheet.png" width="250"> |
| popover | <img src="Resources/xcode26_ios18.6/iphone_compact/popover.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_compact/popover.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_compact/popover.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_compact/popover.png" width="250"> |
| confirmationdialog | <img src="Resources/xcode26_ios18.6/iphone_compact/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_compact/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_compact/confirmationdialog.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_compact/confirmationdialog.png" width="250"> |

## iPhone (regular / rotate)

A close button was added to the share sheet in iOS 27.

| method | Xcode26_ios18 | Xcode26_ios26 | Xcode26_ios27 | Xcode27_ios27 |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/uiactivitycontroller.png" width="250"> |
| sharelink | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/sharelink.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/sharelink.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/sharelink.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/sharelink.png" width="250"> |
| sheet | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/sheet.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/sheet.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/sheet.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/sheet.png" width="250"> |
| popover | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/popover.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/popover.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/popover.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/popover.png" width="250"> |
| confirmationdialog | <img src="Resources/xcode26_ios18.6/iphone_regular_rotate/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios26.5/iphone_regular_rotate/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios27/iphone_regular_rotate/confirmationdialog.png" width="250"> | <img src="Resources/xcode27_ios27/iphone_regular_rotate/confirmationdialog.png" width="250"> |

## iPad (compact)

Same as iPhone (compact): `confirmationDialog` changed from a bottom action sheet to an anchored bubble in iOS 26.

| method | Xcode26_ios18 | Xcode26_ios26 | Xcode26_ios27 | Xcode27_ios27 |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios18.6/ipad_compact/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_compact/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_compact/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_compact/uiactivitycontroller.png" width="250"> |
| sharelink | <img src="Resources/xcode26_ios18.6/ipad_compact/sharelink.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_compact/sharelink.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_compact/sharelink.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_compact/sharelink.png" width="250"> |
| sheet | <img src="Resources/xcode26_ios18.6/ipad_compact/sheet.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_compact/sheet.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_compact/sheet.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_compact/sheet.png" width="250"> |
| popover | <img src="Resources/xcode26_ios18.6/ipad_compact/popover.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_compact/popover.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_compact/popover.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_compact/popover.png" width="250"> |
| confirmationdialog | <img src="Resources/xcode26_ios18.6/ipad_compact/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_compact/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_compact/confirmationdialog.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_compact/confirmationdialog.png" width="250"> |

## iPad (regular)

The height of the sheet changed in iOS 27.

| method | Xcode26_ios18 | Xcode26_ios26 | Xcode26_ios27 | Xcode27_ios27 |
| --- | --- | --- | --- | --- |
| uiactivitycontroller | <img src="Resources/xcode26_ios18.6/ipad_regular/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_regular/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_regular/uiactivitycontroller.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_regular/uiactivitycontroller.png" width="250"> |
| sharelink | <img src="Resources/xcode26_ios18.6/ipad_regular/sharelink.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_regular/sharelink.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_regular/sharelink.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_regular/sharelink.png" width="250"> |
| sheet | <img src="Resources/xcode26_ios18.6/ipad_regular/sheet.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_regular/sheet.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_regular/sheet.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_regular/sheet.png" width="250"> |
| popover | <img src="Resources/xcode26_ios18.6/ipad_regular/popover.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_regular/popover.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_regular/popover.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_regular/popover.png" width="250"> |
| confirmationdialog | <img src="Resources/xcode26_ios18.6/ipad_regular/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios26.5/ipad_regular/confirmationdialog.png" width="250"> | <img src="Resources/xcode26_ios27/ipad_regular/confirmationdialog.png" width="250"> | <img src="Resources/xcode27_ios27/ipad_regular/confirmationdialog.png" width="250"> |
