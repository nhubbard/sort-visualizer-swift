import XCTest

@MainActor
final class NavigationContentUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testEmptySearchExplainsTheStateAndDetailShowsSelectedContent() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let search = app.searchFields["Search Algorithms"]
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
