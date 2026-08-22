import XCTest

/// Drives the app through its main screens for `fastlane snapshot` (see `fastlane/Snapfile`) to
/// capture as App Store screenshots — kept separate from the functional UI tests above so a
/// screenshot pass doesn't also run every correctness test.
@MainActor
final class ScreenshotUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testCaptureAppStoreScreenshots() throws {
    // The simulator itself boots portrait regardless of the app's own Info.plist orientation
    // restriction — has to be rotated explicitly, or `snapshot()` captures a portrait frame.
    XCUIDevice.shared.orientation = .landscapeLeft

    let app = XCUIApplication()
    setupSnapshot(app)
    app.launchEnvironment["UI_TEST_ARRAY_SIZE"] = "24"
    app.launch()

    XCTAssertTrue(app.navigationBars["Sort Symphony v2"].waitForExistence(timeout: 5))
    snapshot("01Home")

    app.tapSidebarLink("algorithmLink.quicksort")
    let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas")
      .firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 5), "visualization canvas never appeared")
    XCTAssertTrue(
      app.staticTexts["sortStatusLabel"].waitForExistence(timeout: 5), "status label never appeared"
    )
    // Let a few operations play out so the shot shows a mid-flight sort, not the very first frame.
    Thread.sleep(forTimeInterval: 1.5)
    snapshot("02SortInProgress")

    app.buttons["showcaseButton"].tap()
    // `.matching(identifier:).firstMatch`, not a plain subscript lookup — see
    // `SettingsUITests`' identical rationale: a `Button` with a custom `.accessibilityIdentifier`
    // inside a `.confirmationDialog` action closure gets wrapped in an extra accessibility
    // container, and the identifier lands on both the wrapper and the real inner button.
    app.buttons.matching(identifier: "showcaseConfirmButton").firstMatch.tap()
    XCTAssertTrue(
      app.staticTexts["showcaseProgressLabel"].waitForExistence(timeout: 5),
      "showcase never appeared")
    Thread.sleep(forTimeInterval: 1.5)
    snapshot("03Showcase")
    app.buttons["showcaseButton"].tap()  // stops it — the same button toggles start/stop now

    app.buttons["settingsButton"].tap()
    XCTAssertTrue(
      app.buttons["visualizerPicker"].waitForExistence(timeout: 5), "settings never appeared")
    snapshot("04Settings")
  }
}
