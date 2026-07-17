import XCTest

/// Proves the scene-level `SortCommands` keyboard shortcuts (`App/Sources/SortCommands.swift`)
/// actually fire, not just that they're declared. `XCUIElement.typeKey(_:modifierFlags:)` delivers
/// a real hardware-keyboard-style event through the same responder chain a live keyboard shortcut
/// or a Mac menu-bar click would use — this is the way to verify a `.keyboardShortcut(...)`-bound
/// `Commands` action end-to-end from a UI test, rather than only asserting it compiles.
@MainActor
final class SortCommandsUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    // See `ScreenshotUITests`'s identical rationale — portrait is a genuinely supported
    // orientation now, so the simulator's own boot orientation would otherwise leak in.
    XCUIDevice.shared.orientation = .landscapeLeft
  }

  func testCommandOpensSettings() throws {
    let app = XCUIApplication()
    app.launch()

    app.typeKey(",", modifierFlags: .command)

    let visualizerPicker = app.buttons["visualizerPicker"]
    XCTAssertTrue(visualizerPicker.waitForExistence(timeout: 5), "⌘, should open Settings")
    app.buttons["Done"].tap()
  }

  /// Directly guards the regression this shortcut was moved to fix: plain ⌘A collided with the
  /// system's own "Select All", which made `UIMenuBuilder` silently drop the command on Mac
  /// Catalyst (see `SortCommands.swift`'s comment on this shortcut, and the ⌥⌘A rebinding).
  func testCommandTogglesSound() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")
    let soundToggle = app.buttons["runControlSoundToggle"]
    XCTAssertTrue(soundToggle.waitForExistence(timeout: 5))
    let before = soundToggle.label

    app.typeKey("a", modifierFlags: [.command, .option])

    XCTAssertNotEqual(soundToggle.label, before, "⌥⌘A should toggle sound")
  }

  func testSpaceTogglesPlayback() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")
    let playPauseButton = app.buttons["runControlPlayPauseButton"]
    XCTAssertTrue(playPauseButton.waitForExistence(timeout: 5))
    let before = playPauseButton.label

    app.typeKey(" ", modifierFlags: [])

    XCTAssertNotEqual(playPauseButton.label, before, "Space should toggle play/pause")
  }
}
