import XCTest

/// Exercises `SettingsView`'s "Reset to Defaults" button end-to-end: mutate a setting via its own
/// control, reset, and confirm it actually lands back on `AppSettings.resetToDefaults()`'s
/// documented value (256 for the default array size) rather than just asserting the button exists.
@MainActor
final class SettingsUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    // See `ScreenshotUITests`'/`DefaultPlaybackSpeedUITests`' identical rationale — portrait is
    // a genuinely supported orientation now, so the simulator's own boot orientation would
    // otherwise leak into this test unpinned.
    XCUIDevice.shared.orientation = .landscapeLeft
  }

  func testResetToDefaultsRestoresDefaultArraySize() throws {
    let app = XCUIApplication()
    app.launch()

    app.buttons["settingsButton"].tap()

    let stepper = app.steppers["defaultArraySizeStepper"]
    scrollUntilVisible(stepper, in: app)
    // A SwiftUI `Stepper`'s two sub-buttons are identified as `<identifier>-Increment`/
    // `-Decrement`, not the bare "Increment"/"Decrement" a UIKit `UIStepper` exposes.
    // Decrement specifically, not Increment: 256 is this stepper's upper bound
    // (`in: 16...256`), and the default IS 256 — incrementing from an already-maxed stepper
    // is a no-op, which is exactly what a previous test's own reset just left this at.
    let previousLabel = stepper.label
    app.buttons["defaultArraySizeStepper-Decrement"].tap()
    XCTAssertNotEqual(stepper.label, previousLabel, "stepper didn't actually move")

    let resetButton = app.buttons["resetSettingsButton"]
    scrollUntilVisible(resetButton, in: app)
    resetButton.tap()

    // `.firstMatch`, not a plain subscript lookup: a `Button` with a custom
    // `.accessibilityIdentifier` inside a `.confirmationDialog` action closure gets wrapped in
    // an extra accessibility container on iPad, and the identifier lands on both the wrapper
    // and the real inner button — two exactly-overlapping matches for the same identifier,
    // deterministically, every time (confirmed via `app.debugDescription`).
    let confirmButton = app.buttons.matching(identifier: "resetSettingsConfirmButton").firstMatch
    XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
    confirmButton.tap()

    XCTAssertTrue(
      stepper.label.hasSuffix(": 256"), "Reset to Defaults should restore the default array size")
  }

  /// Mirrors `DefaultPlaybackSpeedUITests`' own helper — the Settings `Form` doesn't put
  /// off-screen rows in the accessibility tree until scrolled into view.
  private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<5 where !element.exists {
      app.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) never scrolled into view")
  }
}
