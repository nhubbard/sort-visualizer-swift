import XCTest

@MainActor
final class CatalogCompletenessUITests: XCTestCase {
  func testEveryBuiltInAppearsInTheSidebarAndCategoriesStayOrdered() {
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let visibleAlgorithms = scanRows(
      in: app, prefix: "algorithmLink.", listID: "algorithmContentList", limit: 90)
    XCTAssertEqual(Set(visibleAlgorithms), CatalogExpectedIDs.algorithms)
    XCTAssertEqual(visibleAlgorithms.count, CatalogExpectedIDs.algorithms.count)

    let visibleCategories = scanRows(
      in: app, prefix: "sidebarCategory.", listID: "algorithmCategoryList", limit: 20)
    XCTAssertEqual(visibleCategories, ["all"] + CatalogExpectedIDs.categories)

    let quickCategory = app.buttons["sidebarCategory.quick"]
    XCTAssertTrue(quickCategory.waitForExistence(timeout: 5))
    app.activateControlForUITest(quickCategory)
    let quickAlgorithms = scanRows(
      in: app, prefix: "algorithmLink.", listID: "algorithmContentList", limit: 10)
    XCTAssertEqual(Set(quickAlgorithms), ["ternaryllquicksort", "ternarylrquicksort"])
  }

  func testRemovingARegisteredAlgorithmRemovesItsVisibleRow() {
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "24", "UI_TEST_REMOVED_ALGORITHM_ID": "quicksort"
    ]
    app.launch()

    let visibleAlgorithms = scanRows(
      in: app, prefix: "algorithmLink.", listID: "algorithmContentList", limit: 90)
    XCTAssertEqual(Set(visibleAlgorithms), CatalogExpectedIDs.algorithms.subtracting(["quicksort"]))
    XCTAssertEqual(visibleAlgorithms.count, CatalogExpectedIDs.algorithms.count - 1)
    XCTAssertFalse(app.buttons["algorithmLink.quicksort"].exists)
  }

  /// Scroll the real SwiftUI List, collecting its materialized accessibility rows. A List
  /// virtualizes off-screen rows, so querying the tree once cannot establish completeness.
  private func scanRows(
    in app: XCUIApplication, prefix: String, listID: String, limit: Int
  ) -> [String] {
    let list = app.collectionViews[listID]
    XCTAssertTrue(list.waitForExistence(timeout: 10), "Missing catalog list \(listID)")
    var seen = Set<String>()
    var ordered = [String]()
    var unchangedPasses = 0

    for _ in 0..<limit {
      let rows = app.buttons.matching(
        NSPredicate(format: "identifier BEGINSWITH %@", prefix)
      ).allElementsBoundByIndex
      let countBefore = seen.count
      for row in rows {
        let id = String(row.identifier.dropFirst(prefix.count))
        if seen.insert(id).inserted { ordered.append(id) }
      }
      unchangedPasses = seen.count == countBefore ? unchangedPasses + 1 : 0
      if unchangedPasses >= 3 { return ordered }
      #if targetEnvironment(macCatalyst)
        // Keep neighboring rows in the accessibility tree across scrolls. A full-page Catalyst
        // swipe can jump over virtualized rows without ever exposing them to the test.
        list.scroll(byDeltaX: 0, deltaY: -150)
      #else
        list.swipeUp(velocity: .slow)
      #endif
    }
    XCTFail("Catalog list \(listID) did not reach its end within \(limit) scrolls")
    return ordered
  }
}
