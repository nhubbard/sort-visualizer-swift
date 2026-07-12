import XCTest

/// Shared by every UI test that navigates via the algorithm sidebar. `AlgorithmRegistry.shared`
/// has grown to ~80 algorithms across 10 categories over many sessions of porting new ones in —
/// long enough that most category sections don't fit in one screen, and SwiftUI's `List` only
/// materializes near-visible rows as real accessibility elements. A far-down category's link (e.g.
/// `.quick`/`.exchange`, both several categories in) genuinely doesn't `exist` in the accessibility
/// tree — not just "exists but isn't hittable" — until scrolled into view, which is why a plain
/// `waitForExistence`/`.tap()` on it fails outright rather than timing out on visibility.
///
/// Mirrors `DefaultPlaybackSpeedUITests`'s own pre-existing `scrollUntilVisible` helper (written
/// for the Settings `Form`, which has the identical "off-screen row doesn't exist yet" behavior),
/// generalized so every test that reaches into the sidebar shares one implementation instead of
/// each hitting this the same way independently.
extension XCUIApplication {
    /// Scrolls the sidebar list until `identifier`'s button exists (or gives up after
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
    /// separately first.
    func tapSidebarLink(_ identifier: String, maxSwipes: Int = 20) {
        revealSidebarLink(identifier, maxSwipes: maxSwipes).tap()
    }

    /// The sidebar column's own scrollable container — swiping specifically on this (rather than
    /// an unscoped `app.swipeUp()`) is what keeps the gesture from landing on the wider detail
    /// pane next to it, since `NavigationSplitView` shows both at once on iPad. SwiftUI's `List`
    /// backs onto a `UICollectionView` in this app's current SDK/list style; falls back to
    /// `tables` defensively in case that ever changes.
    var sidebarList: XCUIElement {
        collectionViews.firstMatch.exists ? collectionViews.firstMatch : tables.firstMatch
    }
}
