import XCTest

@MainActor
final class ComplexityChartsUITests: XCTestCase {
  func testQuickSortShowsCurrentComplexityAndBothChartStates() {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "100000"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let detail = app.scrollViews["algorithmDetailScrollView"]
    XCTAssertTrue(detail.waitForExistence(timeout: 5))
    let growth = app.descendants(matching: .any)
      .matching(identifier: "growthModelComparisonChart").firstMatch
    for _ in 0..<8 where !growth.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(app.staticTexts["Growth Model"].exists)
    XCTAssertTrue(app.staticTexts["Detected"].exists)
    XCTAssertTrue(app.staticTexts["Fitted (Used by App)"].exists)
    XCTAssertTrue(growth.exists, "Quick Sort's calibrated Growth Model chart is missing")

    let correlation = app.staticTexts["Big-O Correlation"]
    for _ in 0..<8 where !correlation.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(correlation.exists)
    let chart = app.descendants(matching: .any).matching(identifier: "bigOCorrelationChart")
      .firstMatch
    let empty = app.staticTexts["Not Enough Recorded Runs Yet"]
    for _ in 0..<5 where !chart.exists && !empty.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(chart.exists || empty.exists,
      "Big-O must show either recorded data or its explicit sparse-history state")
    if chart.exists {
      let expand = app.buttons["Expand Chart"]
      XCTAssertTrue(expand.exists)
      app.activateControlForUITest(expand)
      #if targetEnvironment(macCatalyst)
      let individualRuns = app.buttons["Show Individual Runs"]
      XCTAssertTrue(individualRuns.waitForExistence(timeout: 5))
      individualRuns.click()
      XCTAssertTrue(app.descendants(matching: .any).matching(
        NSPredicate(format: "label == %@ AND value == %@", "Show Individual Runs", "1")
      ).firstMatch.exists)
      #else
      let individualRuns = app.switches["Show Individual Runs"]
      XCTAssertTrue(individualRuns.waitForExistence(timeout: 5))
      XCTAssertEqual(individualRuns.value as? String, "0")
      app.activateControlForUITest(individualRuns)
      XCTAssertEqual(individualRuns.value as? String, "1")
      #endif
      app.activateControlForUITest(app.buttons["Done"])
      XCTAssertTrue(correlation.exists)
    }
  }

  #if !targetEnvironment(macCatalyst)
  func testExpandedChartControlsFitInPortrait() {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "16", "UI_TEST_PLAYBACK_SPEED": "100000"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    let sorted = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "sorted"), object: status)
    XCTAssertEqual(XCTWaiter().wait(for: [sorted], timeout: 30), .completed)

    app.buttons["runControlSizeButton"].tap()
    let nextSize = app.buttons["runControlSizeChip-32"]
    XCTAssertTrue(nextSize.waitForExistence(timeout: 5))
    nextSize.tap()
    let sizeChanged = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isSelected == true"), object: nextSize)
    XCTAssertEqual(XCTWaiter().wait(for: [sizeChanged], timeout: 10), .completed)

    let detail = app.scrollViews["algorithmDetailScrollView"]
    let chart = app.descendants(matching: .any).matching(identifier: "bigOCorrelationChart")
      .firstMatch
    for _ in 0..<12 where !chart.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(chart.waitForExistence(timeout: 15))
    app.buttons["Expand Chart"].tap()
    let control = app.switches["Show Individual Runs"]
    XCTAssertTrue(control.waitForExistence(timeout: 5))
    XCTAssertGreaterThanOrEqual(control.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(control.frame.maxX, app.frame.maxX)
    control.tap()
    XCTAssertEqual(control.value as? String, "1")
  }
  #endif
}
