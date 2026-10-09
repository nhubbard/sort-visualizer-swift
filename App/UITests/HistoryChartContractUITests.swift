import XCTest

@MainActor
final class HistoryChartContractUITests: XCTestCase {
  private func openQuickSort(scenario: String) -> XCUIApplication {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_HISTORY_SCENARIO": scenario,
      "UI_TEST_ARRAY_SIZE": "16",
      "UI_TEST_PLAYBACK_SPEED": "100000",
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")
    let detail = app.scrollViews["algorithmDetailScrollView"]
    XCTAssertTrue(detail.waitForExistence(timeout: 10))
    let heading = app.staticTexts["Big-O Correlation"]
    for _ in 0..<12 where !heading.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(heading.waitForExistence(timeout: 10))
    return app
  }

  func testSparseHistoryShowsHonestEmptyState() {
    let app = openQuickSort(scenario: "sparse")
    let detail = app.scrollViews["algorithmDetailScrollView"]
    let empty = app.staticTexts["Not Enough Recorded Runs Yet"]
    for _ in 0..<8 where !empty.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(empty.waitForExistence(timeout: 10))
    XCTAssertFalse(app.descendants(matching: .any).matching(
      identifier: "bigOCorrelationChart").firstMatch.exists)
  }

  func testNoHistoryShowsHonestEmptyState() {
    let app = openQuickSort(scenario: "empty")
    let detail = app.scrollViews["algorithmDetailScrollView"]
    let empty = app.staticTexts["Not Enough Recorded Runs Yet"]
    for _ in 0..<8 where !empty.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(empty.waitForExistence(timeout: 10))
  }

  func testStoreFailureShowsErrorState() {
    let app = openQuickSort(scenario: "error")
    let detail = app.scrollViews["algorithmDetailScrollView"]
    let failure = app.staticTexts["Recorded Runs Unavailable"]
    for _ in 0..<8 where !failure.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(failure.waitForExistence(timeout: 10))
    XCTAssertFalse(app.staticTexts["Not Enough Recorded Runs Yet"].exists)
  }

  func testRecordedSizesAndReferenceValuesReachSelection() {
    let app = openQuickSort(scenario: "populated")
    let detail = app.scrollViews["algorithmDetailScrollView"]
    let chart = app.descendants(matching: .any).matching(
      identifier: "bigOCorrelationChart").firstMatch
    for _ in 0..<8 where !chart.exists { detail.swipeUp(velocity: .slow) }
    XCTAssertTrue(chart.waitForExistence(timeout: 10))
    app.activateControlForUITest(app.buttons["Expand Chart"])

    let expanded = app.descendants(matching: .any).matching(
      identifier: "bigOCorrelationExpandedChart").firstMatch
    XCTAssertTrue(expanded.waitForExistence(timeout: 10))
    let selected = app.staticTexts["bigOSelectedSize"]
    let next = app.buttons["Next Recorded Size"]
    XCTAssertTrue(next.waitForExistence(timeout: 5))
    app.activateControlForUITest(next)
    XCTAssertEqual(selected.label, "Array Size 16")
    app.activateControlForUITest(next)
    let sizeSelected = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Array Size 32"), object: selected)
    XCTAssertEqual(XCTWaiter().wait(for: [sizeSelected], timeout: 10), .completed)

    let observed = app.staticTexts["bigOSelection.Observed"]
    let bestAverage = app.staticTexts["bigOSelection.Best & Average Case"]
    let worst = app.staticTexts["bigOSelection.Worst Case"]
    XCTAssertTrue(observed.waitForExistence(timeout: 5))
    XCTAssertTrue(bestAverage.exists)
    XCTAssertTrue(worst.exists)

    let value = Double(observed.label.split(separator: ":").last?
      .trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".") ?? "")
    XCTAssertNotNil(value)
    XCTAssertEqual(value ?? -1, 0.25, accuracy: 0.002)
  }
}
