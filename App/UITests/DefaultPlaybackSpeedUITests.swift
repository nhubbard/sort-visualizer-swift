import XCTest

/// The global default speed feeds every *new* session's starting `ReplayEngine.speed`
/// (`SortSession.startReplay`) — set here via `UI_TEST_PLAYBACK_SPEED` (see `Sort2App.init()`)
/// rather than through the Settings slider: `XCUIElement.adjust(toNormalizedSliderPosition:)` is a
/// coordinate-based drag that lands at a different actual value nearly every run (observed ~48-61
/// when targeting 30), which an exact-value assertion can't tolerate. The launch-environment
/// override mutates the same `AppSettings.playbackSpeed`/`UserDefaults` value a real drag would,
/// just deterministically.
@MainActor
final class DefaultPlaybackSpeedUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    // Now that portrait is a genuinely supported orientation (not just coerced to landscape by
    // iOS), the simulator's own default boot orientation (portrait) would otherwise leak into
    // this test unpinned — see `ScreenshotUITests`' identical rationale.
    XCUIDevice.shared.orientation = .landscapeLeft
  }

  func testChangingDefaultPlaybackSpeedSeedsANewlyOpenedSort() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "195"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")
    let speedButton = app.buttons["runControlSpeedButton"]
    XCTAssertTrue(speedButton.waitForExistence(timeout: 5))
    speedButton.tap()  // expands the inline speed row

    let speedValueLabel = app.staticTexts["runControlSpeedValueLabel"]
    XCTAssertTrue(speedValueLabel.waitForExistence(timeout: 5))
    let sessionSpeed = try XCTUnwrap(
      speedValueLabel.label.split(separator: " ").compactMap { Int($0) }.first)
    XCTAssertEqual(
      sessionSpeed, 195, "a freshly opened sort should start at AppSettings.playbackSpeed")

    // Bonus sanity check in the other direction: the Settings screen's own caption reads the
    // same `AppSettings.playbackSpeed`, so it should reflect the externally-set value too.
    let settingsButton = app.buttons["settingsButton"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
    settingsButton.tap()
    let speedSlider = app.sliders["playbackSpeedSlider"]
    scrollUntilVisible(speedSlider, in: app)
    let caption = app.staticTexts.matching(
      NSPredicate(format: "label ENDSWITH %@", "operations/second")
    ).firstMatch
    XCTAssertTrue(caption.waitForExistence(timeout: 5))
    XCTAssertEqual(caption.label, "195 operations/second")
    app.buttons["Done"].tap()

    // Restore the documented default precisely (a fresh, deterministic relaunch — not a
    // slider drag) so other UI tests' timing assumptions keep holding: `UserDefaults.standard`
    // persists across test runs within the same simulator.
    app.terminate()
    app.launchEnvironment = ["UI_TEST_PLAYBACK_SPEED": "30"]
    app.launch()
  }

  /// The Settings `Form` doesn't put off-screen rows in the accessibility tree until scrolled
  /// into view, and the speed section sits below Visualizer/Shuffle's full picker lists — swipe
  /// incrementally rather than one fixed-distance swipe, which can overshoot past the section
  /// entirely.
  private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<5 where !element.exists {
      app.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) never scrolled into view")
  }
}
