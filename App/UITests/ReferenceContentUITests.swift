import XCTest

@MainActor
final class ReferenceContentUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testSelectedDescriptionEquationsAndCodeLanguagesRender() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let description = app.descendants(matching: .any)
      .matching(identifier: "algorithmDescriptionText").firstMatch
    XCTAssertTrue(description.waitForExistence(timeout: 10))
    XCTAssertTrue(description.label.contains("Quick Sort"))
    XCTAssertTrue(description.label.contains("in-place sorting algorithm"))

    let grid = app.descendants(matching: .any)
      .matching(identifier: "complexityEquationGrid").firstMatch
    XCTAssertTrue(grid.exists)
    for label in ["Best Case", "Average Complexity", "Worst Case", "Space Complexity"] {
      XCTAssertTrue(app.staticTexts[label].exists, "Missing \(label) equation for Quick Sort")
    }

    let scroll = app.scrollViews["algorithmDetailScrollView"]
    let picker = app.segmentedControls["codeLanguagePicker"]
    for _ in 0..<12 where !picker.isHittable { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(picker.isHittable, "reference language picker did not enter the viewport")

    let code = app.descendants(matching: .any)
      .matching(identifier: "algorithmCodeSample").firstMatch
    let summary = app.staticTexts["algorithmCodeSummary"]
    XCTAssertTrue(summary.waitForExistence(timeout: 10))
    XCTAssertTrue(summary.label.contains("Python implementation"))
    XCTAssertFalse(code.exists, "The long listing should be disclosed on request")
    XCTAssertTrue(app.buttons["copyAlgorithmCode"].exists)
    let disclosure = app.buttons["toggleFullAlgorithmCode"]
    app.activateControlForUITest(disclosure)
    XCTAssertTrue(code.waitForExistence(timeout: 10), "Python reference code did not render")
    XCTAssertTrue(code.label.contains("def sort("), "Wrong Python reference code: \(code.label)")
    XCTAssertTrue(code.label.contains("quick_sort"))

    app.activateControlForUITest(picker.buttons["Swift"])
    XCTAssertFalse(code.exists, "Changing languages should return to the short summary")
    XCTAssertTrue(summary.label.contains("Swift implementation"))
    app.activateControlForUITest(disclosure)
    let swiftCode = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS %@", "func sort("), object: code)
    XCTAssertEqual(XCTWaiter().wait(for: [swiftCode], timeout: 10), .completed,
      "Swift selection did not replace the rendered reference code")
    XCTAssertTrue(code.label.contains("quickSort"))
  }

  func testMissingBundledDetailsShowActionableError() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "24", "UI_TEST_MISSING_ALGORITHM_DETAILS": "1"
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let error = app.descendants(matching: .any)
      .matching(identifier: "algorithmDetailsLoadError").firstMatch
    XCTAssertTrue(error.waitForExistence(timeout: 10), "archive failure was not surfaced")
    XCTAssertTrue(app.staticTexts["Reference content unavailable"].exists)
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(
      format: "label CONTAINS %@", "Reinstall the app to restore descriptions and code examples."
    )).firstMatch.exists)
    XCTAssertFalse(app.staticTexts["No description available yet."].exists,
      "archive failure must not appear as ordinary missing editorial content")
    XCTAssertFalse(app.staticTexts["No code samples available yet."].exists)
    XCTAssertTrue(app.descendants(matching: .any)
      .matching(identifier: "complexityEquationGrid").firstMatch.exists,
      "metadata-based complexity must remain available when the reference archive fails")
  }
}
