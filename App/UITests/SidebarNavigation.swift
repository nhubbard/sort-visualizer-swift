import XCTest

/// Shared by every UI test that navigates via the algorithm sidebar. `AlgorithmRegistry.shared`
/// has grown to ~80 algorithms across 10 categories over many sessions of porting new ones in —
/// long enough that most category sections don't fit in one screen, and SwiftUI's `List` only
/// materializes near-visible rows as real accessibility elements. A far-down algorithm's link
/// genuinely doesn't `exist` in the accessibility tree — not just "exists but isn't hittable" —
/// until scrolled into view, which is why a plain `waitForExistence`/`.tap()` on it fails outright
/// rather than timing out on visibility.
///
/// Mirrors `DefaultPlaybackSpeedUITests`'s own pre-existing `scrollUntilVisible` helper (written
/// for the Settings `Form`, which has the identical "off-screen row doesn't exist yet" behavior),
/// generalized so every test that reaches into the sidebar shares one implementation instead of
/// each hitting this the same way independently.
///
/// `ContentView` is a two-tier `NavigationSplitView` (category sidebar → algorithm content →
/// detail) — `sidebarCategory.all`'s "All Algorithms" row is selected by default, so every
/// `algorithmLink.*` is already reachable in the content column without picking a category first.
extension XCUIApplication {
  /// Scrolls the algorithm content list until `identifier`'s button exists (or gives up after
  /// `maxSwipes`), then returns it — for call sites that want to assert existence themselves
  /// with a specific failure message before tapping.
  @discardableResult
  func revealSidebarLink(_ identifier: String, maxSwipes: Int = 20) -> XCUIElement {
    let link = buttons[identifier]
    var attempts = 0
    while !link.exists, attempts < maxSwipes {
      sidebarList.swipeUp(velocity: .slow)
      attempts += 1
    }
    return link
  }

  /// Convenience for call sites that just want the link tapped without asserting existence
  /// separately first. Defensively taps "All Algorithms" first if it's currently reachable —
  /// a harmless no-op when the split view shows every column at once (it's already the default
  /// selection there), but insurance against the untested possibility that a 3-column split
  /// view collapses differently than the 2-column layout this app already empirically confirmed
  /// stays uncollapsed on iPad (see `PortraitOrientationUITests`) — if collapsing ever lands the
  /// content column behind the category sidebar, this is what re-reveals it.
  func tapSidebarLink(_ identifier: String, maxSwipes: Int = 20) {
    let allAlgorithms = buttons["sidebarCategory.all"]
    if allAlgorithms.exists {
      allAlgorithms.tap()
    }
    revealSidebarLink(identifier, maxSwipes: maxSwipes).tap()
  }

  /// The algorithm content column's own scrollable container — swiping specifically on this
  /// (rather than an unscoped `app.swipeUp()`) is what keeps the gesture from landing on the
  /// wider detail pane next to it, or on the category sidebar, since `NavigationSplitView` shows
  /// all three at once on iPad. SwiftUI's `List` backs onto a `UICollectionView` in this app's
  /// current SDK/list style; falls back to `tables` defensively in case that ever changes.
  /// Prefers the explicitly identified content list (`algorithmContentList`) now that there are
  /// two `List`s on screen — the category sidebar is the other one, and `.firstMatch` alone
  /// would grab whichever of the two happens to come first in the tree.
  var sidebarList: XCUIElement {
    let content = collectionViews["algorithmContentList"]
    if content.exists { return content }
    return collectionViews.firstMatch.exists ? collectionViews.firstMatch : tables.firstMatch
  }
}
