import XCTest

/// Shared helpers for UI tests that navigate the algorithm sidebar. `AlgorithmRegistry.shared` has
/// grown to ~80 algorithms across 10 categories, so most category sections don't fit on one
/// screen. SwiftUI's `List` only materializes near-visible rows as accessibility elements — an
/// off-screen link genuinely doesn't `exist` in the tree (not just "exists but unhittable"), so a
/// plain `waitForExistence`/`.tap()` fails outright rather than timing out.
///
/// `ContentView` is a two-tier `NavigationSplitView` (category sidebar → algorithm content →
/// detail); `sidebarCategory.all` is selected by default, so every `algorithmLink.*` is already
/// reachable in the content column without picking a category first.
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

  /// Convenience wrapper that also taps "All Algorithms" first if reachable — a no-op in the
  /// current uncollapsed iPad layout, but ensures the content column is visible if a narrower
  /// layout ever collapses the split view behind the category sidebar.
  func tapSidebarLink(_ identifier: String, maxSwipes: Int = 20) {
    let allAlgorithms = buttons["sidebarCategory.all"]
    if allAlgorithms.exists {
      allAlgorithms.tap()
    }
    revealSidebarLink(identifier, maxSwipes: maxSwipes).tap()
  }

  /// The algorithm content column's own scrollable container. Swiping on this specifically
  /// (rather than an unscoped `app.swipeUp()`) avoids landing on the detail pane or category
  /// sidebar, since `NavigationSplitView` shows all three columns at once on iPad. Prefers
  /// `algorithmContentList` since two `List`s (content + category sidebar) are on screen at
  /// once; falls back to `tables` in case the `List`'s backing view type changes.
  var sidebarList: XCUIElement {
    let content = collectionViews["algorithmContentList"]
    if content.exists { return content }
    return collectionViews.firstMatch.exists ? collectionViews.firstMatch : tables.firstMatch
  }
}
