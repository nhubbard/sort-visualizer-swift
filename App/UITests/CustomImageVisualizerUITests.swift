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
    XCTAssertTrue(app.steppers["defaultArraySizeStepper"].exists)
    app.activateControlForUITest(app.buttons["Done"])

    let canvas = app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 10))
    XCTAssertTrue((canvas.value as? String)?.contains("Custom Image") == true)
    app.activateControlForUITest(app.buttons["runControlVisualizerButton"])
    let runPicker = app.descendants(matching: .any)
      .matching(identifier: "runControlVisualizerPicker").firstMatch
    let tilePicker = app.descendants(matching: .any)
      .matching(identifier: "customImageTileCountPicker").firstMatch
    XCTAssertTrue(app.buttons["customImageChoosePhoto"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["customImageChooseFile"].exists)
    XCTAssertTrue(tilePicker.exists)
    XCTAssertGreaterThan(tilePicker.frame.minX, runPicker.frame.minX)
    XCTAssertLessThan(abs(tilePicker.frame.midY - runPicker.frame.midY), 24)
    XCTAssertGreaterThan(app.buttons["customImageChoosePhoto"].frame.minX,
                         tilePicker.frame.minX)
    app.activateControlForUITest(tilePicker)
    let thirtyTwo = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label == %@", "32")).firstMatch
    XCTAssertTrue(thirtyTwo.waitForExistence(timeout: 5))
    app.activateControlForUITest(thirtyTwo)
    let resized = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value CONTAINS %@", "32 items"), object: canvas)
    XCTAssertEqual(XCTWaiter().wait(for: [resized], timeout: 10), .completed)
  }
}
