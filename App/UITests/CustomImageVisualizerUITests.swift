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
    XCTAssertTrue(app.buttons["customImageChoosePhoto"].exists)
    XCTAssertTrue(app.buttons["customImageChooseFile"].exists)
    XCTAssertTrue(app.staticTexts["customImageSourceStatus"].label.contains("sample image"))
    app.activateControlForUITest(app.buttons["Done"])

    let canvas = app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 10))
    XCTAssertTrue((canvas.value as? String)?.contains("Custom Image") == true)
    app.activateControlForUITest(app.buttons["runControlVisualizerButton"])
    XCTAssertTrue(app.buttons["customImageChoosePhoto"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["customImageChooseFile"].exists)
  }
}
