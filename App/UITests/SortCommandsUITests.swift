import XCTest

/// Proves the scene-level `SortCommands` actions (`App/Sources/SortCommands.swift`) actually fire,
/// not just that they're declared — by clicking the real menu-bar item each one is bound to,
/// rather than `XCUIElement.typeKey(_:modifierFlags:)`. `typeKey`'s synthetic key event was
/// empirically found NOT to reliably reach `NSMenu`'s key-equivalent matching for these
/// `Commands`-declared shortcuts in this automated environment — every one of them (⌘,, ⌥⌘A, bare
/// Space) failed via `typeKey` even after confirming, by hand, that the real keyboard shortcut
/// works when actually pressed. `NSMenu` key-equivalent matching specifically requires the app to
/// be the OS-level *active* application, not just have a visible/key window, which a synthetic
/// CGEvent posted at the accessibility layer doesn't guarantee the same way a real hardware key
/// press does — but clicking the menu item directly triggers its action via the accessibility
/// action protocol, sidestepping key-equivalent matching entirely, and is just as real a
/// user-facing path to the same `Commands` action.
@MainActor
final class SortCommandsUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    // See `ScreenshotUITests`'s identical rationale — portrait is a genuinely supported
    // orientation now, so the simulator's own boot orientation would otherwise leak in.
    XCUIDevice.shared.orientation = .landscapeLeft
  }

  /// Opens `CommandMenu("Sort")` and clicks `itemTitle` — shared by every test in this file
  /// instead of `typeKey`, per this file's own doc comment.
  private func clickSortMenuItem(_ itemTitle: String, in app: XCUIApplication) {
    app.menuBarItems["Sort"].click()
    app.menuItems[itemTitle].click()
  }

  func testCommandOpensSettings() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.navigationBars["Sort Symphony v2"].waitForExistence(timeout: 5))

    clickSortMenuItem("Settings…", in: app)

    let visualizerPicker = app.buttons["visualizerPicker"]
    XCTAssertTrue(visualizerPicker.waitForExistence(timeout: 5), "⌘, should open Settings")
    app.buttons["Done"].tap()
  }

  /// The regression this shortcut was moved to fix (plain ⌘A colliding with the system's own
  /// "Select All", which made `UIMenuBuilder` silently drop the command on Mac Catalyst — see
  /// `SortCommands.swift`'s comment on this shortcut and the ⌥⌘A rebinding) is about the *key
  /// binding* specifically, which clicking the menu item doesn't exercise — only the action it
  /// runs. `typeKey` would verify the binding too, but can't be trusted to reach `NSMenu` here
  /// (see this file's own doc comment); this test settles for verifying the action end-to-end.
  func testCommandTogglesSound() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")
    let soundToggle = app.buttons["runControlSoundToggle"]
    XCTAssertTrue(soundToggle.waitForExistence(timeout: 5))
    let before = soundToggle.label

    clickSortMenuItem("Toggle Sound", in: app)

    // An immediate `.label` read can race the app's own render pass — matches
    // `QuickSortUITests`' own `XCTNSPredicateExpectation` convention for waiting on an
    // accessibility value/label to change, rather than assuming it's already settled the instant
    // the click returns.
    let labelChanged = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label != %@", before), object: soundToggle)
    XCTAssertEqual(
      XCTWaiter().wait(for: [labelChanged], timeout: 5), .completed,
      "the Toggle Sound command should toggle sound")
  }

  func testSpaceTogglesPlayback() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")
    let playPauseButton = app.buttons["runControlPlayPauseButton"]
    XCTAssertTrue(playPauseButton.waitForExistence(timeout: 5))
    let before = playPauseButton.label

    clickSortMenuItem("Play/Pause", in: app)

    // See `testCommandTogglesSound`'s identical rationale for waiting on the label change
    // instead of reading it immediately.
    let labelChanged = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label != %@", before), object: playPauseButton)
    XCTAssertEqual(
      XCTWaiter().wait(for: [labelChanged], timeout: 5), .completed,
      "the Play/Pause command should toggle playback")
  }
}
