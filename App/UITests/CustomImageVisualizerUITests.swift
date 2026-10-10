import XCTest

@MainActor
final class CustomImageVisualizerUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testSampleImageIsAvailableInSettingsAndDuringReplay() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "24",
      "UI_TEST_FRESH_SETTINGS": "1",
      "UI_TEST_FRESH_CUSTOM_IMAGE": "1",
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")
    app.openSettingsForUITest()
    app.activateControlForUITest(app.buttons["visualizerPicker"])
    #if targetEnvironment(macCatalyst)
      let option = app.menuItems["Custom Image"]
    #else
      let option = app.descendants(matching: .any)
        .matching(NSPredicate(format: "label == %@", "Custom Image")).firstMatch
    #endif
    XCTAssertTrue(option.waitForExistence(timeout: 5))
    app.activateControlForUITest(option)
    let settingsPicker = app.descendants(matching: .any)
      .matching(identifier: "visualizerPicker").firstMatch
    XCTAssertTrue(app.buttons["customImageChoosePhoto"].exists)
    XCTAssertTrue(app.buttons["customImageChooseFile"].exists)
    XCTAssertTrue(app.staticTexts["customImageSourceStatus"].label.contains("sample image"))
    XCTAssertGreaterThan(app.buttons["customImageChoosePhoto"].frame.minY,
                         settingsPicker.frame.maxY)
    XCTAssertGreaterThan(app.buttons["customImageChooseFile"].frame.minY,
                         app.buttons["customImageChoosePhoto"].frame.minY)
    let defaultSize = app.steppers["defaultArraySizeStepper"]
    for _ in 0..<5 where !defaultSize.exists { app.scrollSettingsUpForUITest() }
    XCTAssertTrue(defaultSize.exists)
    app.activateControlForUITest(app.buttons["Done"])

    let canvas = app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 10))
    XCTAssertTrue((canvas.value as? String)?.contains("Custom Image") == true)
    app.activateControlForUITest(app.buttons["runControlVisualizerButton"])
    let runPicker = app.descendants(matching: .any)
      .matching(identifier: "runControlVisualizerPicker").firstMatch
    XCTAssertTrue(app.buttons["customImageChoosePhoto"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["customImageChooseFile"].exists)
    XCTAssertFalse(app.descendants(matching: .any)
      .matching(identifier: "customImageTileCountPicker").firstMatch.exists)
    XCTAssertGreaterThan(app.buttons["customImageChoosePhoto"].frame.minX,
                         runPicker.frame.minX)
    XCTAssertLessThan(abs(app.buttons["customImageChoosePhoto"].frame.midY
      - runPicker.frame.midY), 24)
    let rowStart = app.staticTexts["runControlVisualizerLabel"].frame.minX
    let rowEnd = app.staticTexts["customImageSourceStatus"].frame.maxX
    let barCenter = app.scrollViews["runControlVisualizerRowScroll"].frame.midX
    XCTAssertLessThan(abs((rowStart + rowEnd) / 2 - barCenter), 24,
                      "Expanded visualizer controls should be centered in the bar")
    let sizeButton = app.buttons["runControlSizeButton"]
    app.activateControlForUITest(sizeButton)
    let thirtyTwo = app.buttons["runControlSizeChip-32"]
    XCTAssertTrue(thirtyTwo.waitForExistence(timeout: 5))
    app.activateControlForUITest(thirtyTwo)
    let resized = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value CONTAINS %@", "32 items"), object: canvas)
    XCTAssertEqual(XCTWaiter().wait(for: [resized], timeout: 10), .completed)
  }
}
