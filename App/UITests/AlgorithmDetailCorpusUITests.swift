import XCTest

/// Renders every built-in detail page with the shipping description, equation, and chart views.
/// Screenshots are retained in the result bundle for a visual review of crowded or clipped pages.
@MainActor
final class AlgorithmDetailCorpusUITests: XCTestCase {
  func testSmoke() { audit(0..<2) }
  func testPages001Through025() { audit(0..<25) }
  func testPages026Through049() { audit(25..<49) }
  func testPages050Through074() { audit(49..<74) }
  func testPages075Through098() { audit(74..<98) }
  func testPages099Through123() { audit(98..<123) }
  func testPages124Through147() { audit(123..<147) }
  func testPages148Through172() { audit(147..<172) }
  func testPages173Through196() { audit(172..<196) }

  func testDenseExpandedChartScrollsAndChangesSeriesState() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_DETAIL_AUDIT": "1", "UI_TEST_DETAIL_AUDIT_START": "0"]
    app.launch()
    let scroll = app.scrollViews["auditDetailScrollView"]
    let expand = app.buttons["Expand Chart"]
    for _ in 0..<5 where !expand.isHittable { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(expand.isHittable)
    app.activateControlForUITest(expand)
    let chart = app.descendants(matching: .any)
      .matching(identifier: "bigOCorrelationExpandedChart").firstMatch
    XCTAssertTrue(chart.waitForExistence(timeout: 5))
    #if targetEnvironment(macCatalyst)
    // The Catalyst window can be wider than this fixture's entire chart, leaving no horizontal
    // overflow. iPad portrait below exercises the actual scroll movement.
    XCTAssertLessThanOrEqual(chart.frame.maxX, app.frame.maxX + 1)
    let toggle = app.buttons["Show Individual Runs"]
    #else
    let before = chart.screenshot().pngRepresentation
    chart.swipeLeft(velocity: .slow)
    XCTAssertNotEqual(chart.screenshot().pngRepresentation, before,
                      "The expanded chart did not move when scrolled")
    let toggle = app.switches["Show Individual Runs"]
    #endif
    XCTAssertTrue(toggle.exists)
    app.activateControlForUITest(toggle)
    #if !targetEnvironment(macCatalyst)
    XCTAssertEqual(toggle.value as? String, "1")
    chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    XCTAssertTrue(app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Array Size ")
    ).firstMatch.waitForExistence(timeout: 5), "Selecting a chart size did not update its summary")
    #endif
    XCTAssertTrue(chart.exists)
  }

  func testLongFittedEquationCanBeScrolled() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1", "UI_TEST_DETAIL_AUDIT_START": "79",
      "UI_TEST_DETAIL_AUDIT_WIDTH": "900"
    ]
    app.launch()
    XCTAssertEqual(app.staticTexts["auditAlgorithmID"].label, "introcirclesortrecursive")
    let description = app.descendants(matching: .any)
      .matching(identifier: "algorithmDescriptionText").firstMatch
    XCTAssertTrue(description.waitForExistence(timeout: 10), "detail content did not finish loading")
    let equation = app.scrollViews["equationScroll-Fitted (Used by App)"]
    XCTAssertTrue(equation.waitForExistence(timeout: 5))
    let before = equation.screenshot().pngRepresentation
    equation.swipeLeft(velocity: .slow)
    XCTAssertNotEqual(equation.screenshot().pngRepresentation, before,
                      "The long fitted equation did not reveal its remaining terms")
  }

  private func audit(_ range: Range<Int>) {
    continueAfterFailure = false
    #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .portrait
    #endif
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1",
      "UI_TEST_DETAIL_AUDIT_START": String(range.lowerBound),
      "UI_TEST_DETAIL_AUDIT_WIDTH": "900"
    ]
    app.launch()
    let scroll = app.scrollViews["auditDetailScrollView"]
    XCTAssertTrue(scroll.waitForExistence(timeout: 10))

    var seen = Set<String>()
    for offset in range {
      let id = app.staticTexts["auditAlgorithmID"]
      let position = app.staticTexts["auditIndexLabel"]
      XCTAssertTrue(id.waitForExistence(timeout: 5))
      XCTAssertEqual(position.label, "\(offset + 1) of 196")
      let algorithmID = id.label
      XCTAssertTrue(seen.insert(algorithmID).inserted, "Duplicate page \(algorithmID)")
      XCTContext.runActivity(named: "\(offset + 1) \(algorithmID)") { activity in
        let description = app.descendants(matching: .any)
          .matching(identifier: "algorithmDescriptionText").firstMatch
        XCTAssertTrue(description.waitForExistence(timeout: 10), "Missing description for \(algorithmID)")
        XCTAssertTrue(app.staticTexts["Description"].isHittable,
                      "Detail page did not reset to the top for \(algorithmID)")
        for label in ["Best Case", "Average Complexity", "Worst Case", "Space Complexity", "Implementation Complexity",
                      "Growth Model", "Fitted (Used by App)", "Big-O Correlation"] {
          XCTAssertTrue(app.staticTexts[label].exists, "Missing \(label) for \(algorithmID)")
        }
        let top = XCTAttachment(screenshot: app.screenshot())
        top.name = "\(String(format: "%03d", offset + 1))-\(algorithmID)-top"
        top.lifetime = .keepAlways
        activity.add(top)

        let growth = app.descendants(matching: .any)
          .matching(identifier: "growthModelComparisonChart").firstMatch
        let noMeasuredModel = app.staticTexts["A measured growth model is not available for this algorithm yet."]
        XCTAssertTrue(growth.exists || noMeasuredModel.exists,
                      "Growth Model has no chart or explicit fallback for \(algorithmID)")
        let correlation = app.descendants(matching: .any)
          .matching(identifier: "bigOCorrelationChart").firstMatch
        XCTAssertTrue(correlation.waitForExistence(timeout: 10),
                      "Populated Big-O chart is missing for \(algorithmID)")

        let expandButton = app.buttons["Expand Chart"]
        // Catalyst's swipe can jump past the button on long descriptions. Move toward its
        // accessibility frame in measured steps, leaving room around it for a reliable click.
        for _ in 0..<30 {
          if expandButton.isHittable,
             expandButton.frame.minY >= scroll.frame.minY + 24,
             expandButton.frame.maxY <= scroll.frame.maxY - 24 { break }
          #if targetEnvironment(macCatalyst)
          let delta = expandButton.frame.maxY > scroll.frame.maxY - 24 ? -150.0 : 150.0
          scroll.scroll(byDeltaX: 0, deltaY: delta)
          #else
          if expandButton.frame.maxY > scroll.frame.maxY - 24 {
            scroll.swipeUp(velocity: .slow)
          } else {
            scroll.swipeDown(velocity: .slow)
          }
          #endif
        }
        XCTAssertTrue(expandButton.isHittable)
        XCTAssertGreaterThanOrEqual(expandButton.frame.minY, scroll.frame.minY + 24)
        XCTAssertLessThanOrEqual(expandButton.frame.maxY, scroll.frame.maxY - 24)
        let bottom = XCTAttachment(screenshot: app.screenshot())
        bottom.name = "\(String(format: "%03d", offset + 1))-\(algorithmID)-charts"
        bottom.lifetime = .keepAlways
        activity.add(bottom)

        app.activateControlForUITest(expandButton)
        let expanded = app.descendants(matching: .any)
          .matching(identifier: "bigOCorrelationExpandedChart").firstMatch
        XCTAssertTrue(expanded.waitForExistence(timeout: 5),
                      "Expanded Big-O chart is missing for \(algorithmID)")
        XCTAssertGreaterThan(expanded.frame.width, 200)
        XCTAssertLessThanOrEqual(expanded.frame.maxX, app.frame.maxX + 1)
        let referenceLegend = app.descendants(matching: .any)
          .matching(identifier: "bigOReferenceLegend").firstMatch
        XCTAssertTrue(referenceLegend.exists)
        XCTAssertLessThanOrEqual(referenceLegend.frame.maxX, expanded.frame.maxX + 1,
                                 "Reference-series legend is clipped for \(algorithmID)")
        #if targetEnvironment(macCatalyst)
        XCTAssertTrue(app.buttons["Show Individual Runs"].exists)
        #else
        XCTAssertTrue(app.switches["Show Individual Runs"].exists)
        #endif
        let large = XCTAttachment(screenshot: app.screenshot())
        large.name = "\(String(format: "%03d", offset + 1))-\(algorithmID)-expanded"
        large.lifetime = .keepAlways
        activity.add(large)
        app.activateControlForUITest(app.buttons["Done"])
      }
      if offset < range.upperBound - 1 {
        app.activateControlForUITest(app.buttons["auditNextButton"])
      }
    }
    XCTAssertEqual(seen.count, range.count)
  }
}

/// The regular corpus audit covers wide pages. This renders the same shipping Growth Model
/// section at an iPad split-window width and retains every full-resolution capture for review.
@MainActor
final class GrowthModelNarrowCorpusUITests: XCTestCase {
  func testPages001Through025() { audit(0..<25) }
  func testPages026Through049() { audit(25..<49) }
  func testPages050Through074() { audit(49..<74) }
  func testPages075Through098() { audit(74..<98) }
  func testPages099Through123() { audit(98..<123) }
  func testPages124Through147() { audit(123..<147) }
  func testPages148Through172() { audit(147..<172) }
  func testPages173Through196() { audit(172..<196) }

  private func audit(_ range: Range<Int>) {
    continueAfterFailure = false
    #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .portrait
    #endif
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1",
      "UI_TEST_DETAIL_AUDIT_START": String(range.lowerBound),
      "UI_TEST_DETAIL_AUDIT_WIDTH": "360",
      "UI_TEST_GROWTH_ONLY": "1"
    ]
    app.launch()
    let scroll = app.scrollViews["auditDetailScrollView"]
    XCTAssertTrue(scroll.waitForExistence(timeout: 10))

    var seen = Set<String>()
    for offset in range {
      let id = app.staticTexts["auditAlgorithmID"]
      let position = app.staticTexts["auditIndexLabel"]
      XCTAssertTrue(id.waitForExistence(timeout: 5))
      XCTAssertEqual(position.label, "\(offset + 1) of 196")
      let algorithmID = id.label
      XCTAssertTrue(seen.insert(algorithmID).inserted, "Duplicate page \(algorithmID)")
      let growth = app.descendants(matching: .any)
        .matching(identifier: "growthModelComparisonChart").firstMatch
      XCTAssertTrue(growth.waitForExistence(timeout: 10), "Missing Growth Model for \(algorithmID)")
      XCTAssertGreaterThan(growth.frame.width, 200, "Chart is too narrow for \(algorithmID)")
      XCTAssertLessThanOrEqual(growth.frame.width, 297,
                               "Chart exceeds its padded 296-point column for \(algorithmID)")
      XCTAssertGreaterThanOrEqual(growth.frame.minX, scroll.frame.minX - 1)
      XCTAssertLessThanOrEqual(growth.frame.maxX, scroll.frame.maxX + 1)
      XCTAssertTrue(app.staticTexts.matching(
        NSPredicate(format: "label BEGINSWITH %@", "Dotted line: maximum selectable size (")
      ).firstMatch.exists, "Missing cutoff explanation for \(algorithmID)")
      XCTContext.runActivity(named: "\(offset + 1) \(algorithmID)") { activity in
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "growth-360-\(String(format: "%03d", offset + 1))-\(algorithmID)"
        capture.lifetime = .keepAlways
        activity.add(capture)
      }
      if offset < range.upperBound - 1 {
        app.activateControlForUITest(app.buttons["auditNextButton"])
      }
    }
    XCTAssertEqual(seen.count, range.count)
  }
}

/// Audits the shipping compact Big-O panel at its narrowest supported detail width.
@MainActor
final class CompactBigONarrowCorpusUITests: XCTestCase {
  func testPages001Through025() { audit(0..<25) }
  func testPages026Through049() { audit(25..<49) }
  func testPages050Through074() { audit(49..<74) }
  func testPages075Through098() { audit(74..<98) }
  func testPages099Through123() { audit(98..<123) }
  func testPages124Through147() { audit(123..<147) }
  func testPages148Through172() { audit(147..<172) }
  func testPages173Through196() { audit(172..<196) }

  private func audit(_ range: Range<Int>) {
    continueAfterFailure = false
    #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .portrait
    #endif
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1",
      "UI_TEST_DETAIL_AUDIT_START": String(range.lowerBound),
      "UI_TEST_DETAIL_AUDIT_WIDTH": "360",
      "UI_TEST_COMPACT_BIGO_ONLY": "1"
    ]
    app.launch()
    let scroll = app.scrollViews["auditDetailScrollView"]
    XCTAssertTrue(scroll.waitForExistence(timeout: 10))

    var seen = Set<String>()
    for offset in range {
      let id = app.staticTexts["auditAlgorithmID"]
      let position = app.staticTexts["auditIndexLabel"]
      XCTAssertTrue(id.waitForExistence(timeout: 5))
      XCTAssertEqual(position.label, "\(offset + 1) of 196")
      let algorithmID = id.label
      XCTAssertTrue(seen.insert(algorithmID).inserted, "Duplicate page \(algorithmID)")
      let chart = app.descendants(matching: .any)
        .matching(identifier: "bigOCorrelationChart").firstMatch
      XCTAssertTrue(chart.waitForExistence(timeout: 10), "Missing compact Big-O chart for \(algorithmID)")
      XCTAssertGreaterThan(chart.frame.width, 200, "Chart is too narrow for \(algorithmID)")
      XCTAssertLessThanOrEqual(chart.frame.width, 297,
                               "Chart exceeds its padded 296-point column for \(algorithmID)")
      XCTAssertGreaterThanOrEqual(chart.frame.minX, scroll.frame.minX - 1)
      XCTAssertLessThanOrEqual(chart.frame.maxX, scroll.frame.maxX + 1)
      let legend = app.descendants(matching: .any)
        .matching(identifier: "bigOCompactLegend").firstMatch
      XCTAssertTrue(legend.exists, "Missing compact legend for \(algorithmID)")
      XCTAssertLessThanOrEqual(legend.frame.maxX, scroll.frame.maxX + 1,
                               "Legend clipped for \(algorithmID)")
      let expand = app.buttons["Expand Chart"]
      XCTAssertTrue(expand.exists, "Missing expanded-chart control for \(algorithmID)")
      XCTAssertLessThanOrEqual(expand.frame.maxX, scroll.frame.maxX + 9,
                               "Expanded-chart control clipped for \(algorithmID)")
      XCTContext.runActivity(named: "\(offset + 1) \(algorithmID)") { activity in
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "compact-bigo-360-\(String(format: "%03d", offset + 1))-\(algorithmID)"
        capture.lifetime = .keepAlways
        activity.add(capture)
      }
      if offset < range.upperBound - 1 {
        app.activateControlForUITest(app.buttons["auditNextButton"])
      }
    }
    XCTAssertEqual(seen.count, range.count)
  }
}
