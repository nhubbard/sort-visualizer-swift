import XCTest

/// Device rotation has no Catalyst equivalent. Keep the iPad orientation deterministic while
/// allowing the same functional journeys to run on Mac.
@MainActor
func useLandscapeOrientationForUITest() {
  #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .landscapeLeft
  #endif
}

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
  func activateControlForUITest(_ control: XCUIElement) {
    #if targetEnvironment(macCatalyst)
      control.click()
    #else
      control.tap()
    #endif
  }

  func openSettingsForUITest() {
    #if targetEnvironment(macCatalyst)
      // SwiftUI's identifier is dropped when the button becomes an NSToolbar item.
      let button = buttons["Gear shape"]
      XCTAssertTrue(button.waitForExistence(timeout: 5), "settings toolbar button is missing")
      button.click()
    #else
      let button = buttons["settingsButton"]
      XCTAssertTrue(button.waitForExistence(timeout: 5), "settings toolbar button is missing")
      button.tap()
    #endif
  }

  func scrollSettingsUpForUITest() {
    #if targetEnvironment(macCatalyst)
      // The application root is disabled while a native settings sheet is open.
      let settingsList = sheets.firstMatch.collectionViews.firstMatch
      XCTAssertTrue(settingsList.exists, "Settings list is missing from its native sheet")
      settingsList.scroll(byDeltaX: 0, deltaY: -150)
    #else
      swipeUp(velocity: .slow)
    #endif
  }

  func scrollSettingsDownForUITest() {
    #if targetEnvironment(macCatalyst)
      let settingsList = sheets.firstMatch.collectionViews.firstMatch
      XCTAssertTrue(settingsList.exists, "Settings list is missing from its native sheet")
      settingsList.scroll(byDeltaX: 0, deltaY: 120)
    #else
      swipeDown(velocity: .slow)
    #endif
  }

  /// Scrolls the algorithm content list until `identifier`'s button exists (or gives up after
  /// `maxSwipes`), then returns it — for call sites that want to assert existence themselves
  /// with a specific failure message before tapping.
  @discardableResult
  func revealSidebarLink(_ identifier: String, maxSwipes: Int = 20) -> XCUIElement {
    let link = buttons[identifier]
    #if targetEnvironment(macCatalyst)
      // The Catalyst content list can scroll past a virtualized row in one swipe. Search is
      // available in its navigation bar and narrows the real registry-backed list instead.
      let searchTerms = [
        "algorithmLink.quicksort": "Quick Sort",
        "algorithmLink.bubblesort": "Bubble Sort",
        "algorithmLink.gnomesort": "Gnome Sort",
      ]
      if !link.exists, let term = searchTerms[identifier] {
        let search = searchFields["Search Algorithms"]
        if search.waitForExistence(timeout: 5) {
          search.click()
          search.typeKey("a", modifierFlags: .command)
          search.typeText(term)
          if link.waitForExistence(timeout: 5) { return link }
        }
      }
    #endif
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
    #if !targetEnvironment(macCatalyst)
    let allAlgorithms = buttons["sidebarCategory.all"]
    if allAlgorithms.exists {
      allAlgorithms.tap()
    }
    #endif
    activateSidebarLink(revealSidebarLink(identifier, maxSwipes: maxSwipes))
  }

  func activateSidebarLink(_ link: XCUIElement) {
    #if targetEnvironment(macCatalyst)
      link.click()
    #else
      link.tap()
    #endif
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
