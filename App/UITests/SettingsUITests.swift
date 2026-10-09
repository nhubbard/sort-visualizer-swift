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
    useLandscapeOrientationForUITest()
  }

  func testResetToDefaultsRestoresDefaultArraySize() throws {
    let app = XCUIApplication()
    app.launch()

    app.openSettingsForUITest()

    let stepper = defaultSizeControl(in: app)
    scrollUntilVisible(stepper, in: app)
    // A SwiftUI `Stepper`'s two sub-buttons are identified as `<identifier>-Increment`/
    // `-Decrement`, not the bare "Increment"/"Decrement" a UIKit `UIStepper` exposes.
    // Decrement specifically, not Increment: 256 is this stepper's upper bound
    // (`in: 16...256`), and the default IS 256 — incrementing from an already-maxed stepper
    // is a no-op, which is exactly what a previous test's own reset just left this at.
    let previousLabel = stepper.label
    changeDefaultSize(in: app, decrement: true)
    XCTAssertNotEqual(stepper.label, previousLabel, "stepper didn't actually move")

    let resetButton = app.buttons["resetSettingsButton"]
    scrollUntilVisible(resetButton, in: app)
    app.activateControlForUITest(resetButton)

    // `.firstMatch`, not a plain subscript lookup: a `Button` with a custom
    // `.accessibilityIdentifier` inside a `.confirmationDialog` action closure gets wrapped in
    // an extra accessibility container on iPad, and the identifier lands on both the wrapper
    // and the real inner button — two exactly-overlapping matches for the same identifier,
    // deterministically, every time (confirmed via `app.debugDescription`).
    let confirmButton = resetConfirmationButton(in: app)
    XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
    app.activateControlForUITest(confirmButton)

    let restored = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label ENDSWITH %@", ": 256"), object: stepper)
    XCTAssertEqual(XCTWaiter().wait(for: [restored], timeout: 5), .completed,
      "Reset to Defaults should restore the default array size")
  }

  func testFixedDurationPacingShowsItsControlsAndRestoresFixedRate() throws {
    let app = XCUIApplication()
    app.launch()
    app.openSettingsForUITest()

    let pacingPicker = app.segmentedControls["pacingModePicker"]
    scrollUntilVisible(pacingPicker, in: app)
    app.activateControlForUITest(pacingPicker.buttons["Fixed Duration"])

    let durationSlider = app.sliders["targetPlaybackDurationSlider"]
    XCTAssertTrue(durationSlider.waitForExistence(timeout: 5))
    XCTAssertFalse(app.sliders["playbackSpeedSlider"].exists)
    XCTAssertTrue(app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS %@", "per run")
    ).firstMatch.exists)

    app.activateControlForUITest(pacingPicker.buttons["Fixed Rate"])
    XCTAssertTrue(app.sliders["playbackSpeedSlider"].waitForExistence(timeout: 5))
    XCTAssertFalse(durationSlider.exists)
  }

  func testArraySizeChangePersistsAcrossAppRelaunch() throws {
    let app = XCUIApplication()
    app.launch()
    app.openSettingsForUITest()

    var stepper = defaultSizeControl(in: app)
    scrollUntilVisible(stepper, in: app)
    let original = stepper.label
    changeDefaultSize(in: app, decrement: !stepper.label.hasSuffix(": 16"))
    let changed = stepper.label
    XCTAssertNotEqual(changed, original)

    app.terminate()
    app.launch()
    app.openSettingsForUITest()
    stepper = defaultSizeControl(in: app)
    scrollUntilVisible(stepper, in: app)
    XCTAssertEqual(stepper.label, changed, "the saved setting did not survive a new process")

    let reset = app.buttons["resetSettingsButton"]
    scrollUntilVisible(reset, in: app)
    app.activateControlForUITest(reset)
    app.activateControlForUITest(resetConfirmationButton(in: app))
    let restored = NSPredicate(format: "label ENDSWITH %@", ": 256")
    expectation(for: restored, evaluatedWith: stepper)
    waitForExpectations(timeout: 5)
  }

  func testFreshLaunchRecoversMalformedSettingsAndResetPersistsEveryDefault() {
    let app = XCUIApplication()
    let expected = "bargraph|30.0|false|10.0|false|false|false|36-72|256|300000|monokai|random"
    app.launchEnvironment = ["UI_TEST_FRESH_SETTINGS": "1", "UI_TEST_SETTINGS_AUDIT": "1"]
    app.launch()
    app.openSettingsForUITest()
    let audit = app.staticTexts["settingsAuditProbe"]
    XCTAssertTrue(audit.waitForExistence(timeout: 5))
    XCTAssertEqual(audit.value as? String, expected)

    let pacing = app.segmentedControls["pacingModePicker"]
    scrollUntilVisible(pacing, in: app)
    app.activateControlForUITest(pacing.buttons["Fixed Duration"])
    let modified = expected.replacingOccurrences(of: "|false|10.0|", with: "|true|10.0|")
    XCTAssertEqual(audit.value as? String, modified)

    app.terminate()
    app.launchEnvironment = ["UI_TEST_SETTINGS_AUDIT": "1"]
    app.launch()
    app.openSettingsForUITest()
    XCTAssertEqual(audit.value as? String, modified, "the changed pacing mode should survive relaunch")

    app.terminate()
    app.launchEnvironment = ["UI_TEST_SETTINGS_AUDIT": "1", "UI_TEST_CORRUPT_SETTINGS": "1"]
    app.launch()
    app.openSettingsForUITest()
    XCTAssertEqual(audit.value as? String, expected, "malformed saved values should recover in a fresh UI")
    XCTAssertTrue(app.sliders["playbackSpeedSlider"].exists)
    let size = defaultSizeControl(in: app)
    scrollUntilVisible(size, in: app)
    XCTAssertTrue(size.label.hasSuffix(": 256"))

    let reset = app.buttons["resetSettingsButton"]
    scrollUntilVisible(reset, in: app)
    app.activateControlForUITest(reset)
    app.activateControlForUITest(resetConfirmationButton(in: app))
    app.terminate()
    app.launchEnvironment = ["UI_TEST_SETTINGS_AUDIT": "1"]
    app.launch()
    app.openSettingsForUITest()
    XCTAssertEqual(audit.value as? String, expected, "reset should persist every default field")
  }

  func testSavedSettingsReachNewRunAndActiveControlsAfterRelaunch() {
    let app = XCUIApplication()
    let expectedSettings =
      "rainbow|195.0|true|1.0|false|true|false|36-72|32|300000|dracula|descending"
    let expectedRun = "true|32|195.0|true|1.0|descending|rainbow"
    app.launchEnvironment = [
      "UI_TEST_FRESH_SETTINGS": "1", "UI_TEST_SET02_PRESET": "1",
      "UI_TEST_SETTINGS_AUDIT": "1", "UI_TEST_ACTIVE_SETTINGS_AUDIT": "1",
    ]
    app.launch()
    app.openSettingsForUITest()
    let settingsProbe = app.staticTexts["settingsAuditProbe"]
    XCTAssertTrue(settingsProbe.waitForExistence(timeout: 5))
    XCTAssertEqual(settingsProbe.value as? String, expectedSettings)

    app.terminate()
    app.launchEnvironment = [
      "UI_TEST_SETTINGS_AUDIT": "1", "UI_TEST_ACTIVE_SETTINGS_AUDIT": "1",
    ]
    app.launch()
    app.openSettingsForUITest()
    XCTAssertEqual(settingsProbe.value as? String, expectedSettings)
    XCTAssertTrue(app.sliders["targetPlaybackDurationSlider"].exists)
    app.activateControlForUITest(app.buttons["Done"])

    app.tapSidebarLink("algorithmLink.quicksort")
    let active = app.staticTexts["activeSettingsProbe"]
    XCTAssertTrue(active.waitForExistence(timeout: 10))
    XCTAssertEqual(active.value as? String, expectedRun)
    XCTAssertEqual(app.buttons["runControlSoundToggle"].label, "Mute")
    let theme = app.staticTexts["codeThemeAppliedProbe"]
    XCTAssertTrue(theme.waitForExistence(timeout: 15))
    let applied = theme.value as? String ?? ""
    XCTAssertTrue(applied.hasPrefix("dracula|"), "code theme was not applied: \(applied)")
    XCTAssertGreaterThan(Int(applied.split(separator: "|").last ?? "0") ?? 0, 0)

    app.activateControlForUITest(app.buttons["runControlSoundToggle"])
    XCTAssertEqual(active.value as? String,
      "false|32|195.0|true|1.0|descending|rainbow")
    app.openSettingsForUITest()
    XCTAssertEqual(settingsProbe.value as? String, expectedSettings,
      "the active sound toggle must not overwrite the saved default")
    app.activateControlForUITest(app.buttons["Done"])

    app.tapSidebarLink("algorithmLink.selectionsort")
    XCTAssertEqual(active.value as? String, expectedRun,
      "a new session should seed sound and all run settings from persisted defaults")

    app.openSettingsForUITest()
    app.activateControlForUITest(app.buttons["visualizerPicker"])
    #if targetEnvironment(macCatalyst)
      let barGraph = app.menuItems["Bar Graph"]
    #else
      let barGraph = app.descendants(matching: .any)
        .matching(NSPredicate(format: "label == %@", "Bar Graph")).firstMatch
    #endif
    XCTAssertTrue(barGraph.waitForExistence(timeout: 5))
    app.activateControlForUITest(barGraph)
    app.activateControlForUITest(app.buttons["Done"])
    XCTAssertEqual(active.value as? String, "true|32|195.0|true|1.0|descending|bargraph")

    app.openSettingsForUITest()
    let reset = app.buttons["resetSettingsButton"]
    scrollUntilVisible(reset, in: app)
    app.activateControlForUITest(reset)
    app.activateControlForUITest(resetConfirmationButton(in: app))
  }

  /// Mirrors `DefaultPlaybackSpeedUITests`' own helper — the Settings `Form` doesn't put
  /// off-screen rows in the accessibility tree until scrolled into view.
  private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 where !element.exists {
      app.scrollSettingsUpForUITest()
    }
    XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) never scrolled into view")
    #if targetEnvironment(macCatalyst)
      // The form can materialize a row just behind its fixed navigation bar. Move it down
      // into the sheet before clicking the native stepper arrows.
      let top = app.sheets.firstMatch.frame.minY + 100
      for _ in 0..<3 {
        guard element.exists, element.frame.midY < top else { break }
        app.scrollSettingsDownForUITest()
      }
    #endif
  }

  private func defaultSizeControl(in app: XCUIApplication) -> XCUIElement {
    #if targetEnvironment(macCatalyst)
      // Catalyst exposes SwiftUI's Stepper as an Other element with its label and value.
      return app.otherElements["defaultArraySizeStepper"]
    #else
      return app.steppers["defaultArraySizeStepper"]
    #endif
  }

  private func resetConfirmationButton(in app: XCUIApplication) -> XCUIElement {
    #if targetEnvironment(macCatalyst)
      return app.sheets["alert"].buttons["Reset to Defaults"]
    #else
      return app.buttons.matching(identifier: "resetSettingsConfirmButton").firstMatch
    #endif
  }

  private func changeDefaultSize(in app: XCUIApplication, decrement: Bool) {
    #if targetEnvironment(macCatalyst)
      let stepper = defaultSizeControl(in: app)
      XCTAssertTrue(stepper.exists)
      // The native stepper's up/down arrows are visually present but absent as separate AX
      // buttons. Click the trailing upper/lower half of its accessible frame.
      stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: decrement ? 0.75 : 0.25))
        .click()
    #else
      app.buttons["defaultArraySizeStepper-\(decrement ? "Decrement" : "Increment")"].tap()
    #endif
  }
}
