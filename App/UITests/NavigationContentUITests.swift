import XCTest

@MainActor
final class NavigationContentUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testHomeExampleOpensSortAndHelpExplainsControls() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1",
      "UI_TEST_DISCOVERY_TIPS": "1",
    ]
    app.launch()

    let example = app.buttons["homeTryQuickSortButton"]
    XCTAssertTrue(example.waitForExistence(timeout: 5))
    XCTAssertEqual(example.label, "Try Quick Sort")
    app.activateControlForUITest(example)

    XCTAssertTrue(app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch.waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["sortDetailsScrollCue"].exists)
    let playbackTip = app.descendants(matching: .any)
      .matching(identifier: "sortPlaybackTip").firstMatch
    XCTAssertTrue(playbackTip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Explore one step at a time"].exists)
    let help = app.buttons["sortHelpButton"]
    XCTAssertEqual(help.label, "How to Use")
    app.activateControlForUITest(help)
    XCTAssertTrue(app.staticTexts["Use Play to watch the recording. Pause and use Step Forward or Step Back to inspect one operation at a time."].waitForExistence(timeout: 5))
    app.activateControlForUITest(app.buttons["sortHelpDoneButton"])
    XCTAssertTrue(help.waitForExistence(timeout: 5))
    app.activateControlForUITest(app.buttons["runControlStepForwardButton"])
    let presentationTip = app.descendants(matching: .any)
      .matching(identifier: "sortPresentationTip").firstMatch
    XCTAssertTrue(presentationTip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Change the view"].exists)
    app.activateControlForUITest(app.buttons["runControlSizeButton"])
    XCTAssertTrue(app.buttons["runControlSizeChip-16"].waitForExistence(timeout: 5))
  }

  func testEmptySearchExplainsTheStateAndDetailShowsSelectedContent() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let search = app.searchFields["Search"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    app.activateControlForUITest(search)
    search.typeText("no algorithm has this name 476829")
    XCTAssertTrue(app.staticTexts["No Matching Algorithms"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Try another name or category."].exists)
    XCTAssertFalse(app.buttons["algorithmLink.quicksort"].exists)

    app.terminate()
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")
    let description = app.descendants(matching: .any)
      .matching(identifier: "algorithmDescriptionText").firstMatch
    XCTAssertTrue(description.waitForExistence(timeout: 10), "Quick Sort description did not load")
    XCTAssertTrue(description.label.localizedCaseInsensitiveContains("Quick Sort"),
                  "The selected algorithm's description is missing: \(description.label)")
    XCTAssertTrue(app.staticTexts["Best Case"].exists)
    XCTAssertTrue(app.staticTexts["Worst Case"].exists)
    XCTAssertTrue(app.staticTexts["Big-O Correlation"].exists)

    let scroll = app.scrollViews["algorithmDetailScrollView"]
    let languagePicker = app.segmentedControls["codeLanguagePicker"]
    for _ in 0 ..< 12 where !languagePicker.exists { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(languagePicker.exists, "Selected algorithm's reference implementations are missing")
    XCTAssertTrue(languagePicker.buttons["Swift"].exists)
  }
}
