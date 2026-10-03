import XCTest

@MainActor
final class RecordingLimitUITests: XCTestCase {
  func testManualRecordingLimitShowsAReasonInsteadOfAnIncorrectReplay() {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_RECORDING_CAP": "5"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    let failed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "failed"), object: status)
    XCTAssertEqual(XCTWaiter().wait(for: [failed], timeout: 10), .completed)
    XCTAssertTrue(app.staticTexts["Sort Skipped"].exists)
    XCTAssertTrue(app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS %@", "operation limit")
    ).firstMatch.exists)
    XCTAssertFalse(app.buttons["runControlPlayPauseButton"].exists)
  }
}
