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
  func testNarrowSmoke() { audit(0..<2, width: 360, prefix: "narrow-") }
  func testNarrowPages001Through025() { audit(0..<25, width: 360, prefix: "narrow-") }
  func testNarrowPages026Through049() { audit(25..<49, width: 360, prefix: "narrow-") }
  func testNarrowPages050Through074() { audit(49..<74, width: 360, prefix: "narrow-") }
  func testNarrowPages075Through098() { audit(74..<98, width: 360, prefix: "narrow-") }
  func testNarrowPages099Through123() { audit(98..<123, width: 360, prefix: "narrow-") }
  func testNarrowPages124Through147() { audit(123..<147, width: 360, prefix: "narrow-") }
  func testNarrowPages148Through172() { audit(147..<172, width: 360, prefix: "narrow-") }
  func testNarrowPages173Through196() { audit(172..<196, width: 360, prefix: "narrow-") }

  func testLongestDescriptionsReachTheirEndingAtNarrowWidth() {
    continueAfterFailure = false
    let fixtures: [(index: Int, id: String, ending: String)] = [
      (79, "introcirclesortrecursive", "using no auxiliary array of its own."),
      (91, "laziestsort", "Most merge sort variants trade rotations for a full-sized scratch buffer."),
      (169, "stacklessrotatemergesort", "so is the sort as a whole.")
    ]
    for fixture in fixtures {
      let app = XCUIApplication()
      app.launchEnvironment = [
        "UI_TEST_DETAIL_AUDIT": "1",
        "UI_TEST_DETAIL_AUDIT_START": String(fixture.index),
        "UI_TEST_DETAIL_AUDIT_WIDTH": "360"
      ]
      app.launch()
      XCTAssertEqual(app.staticTexts["auditAlgorithmID"].label, fixture.id)
      let description = app.descendants(matching: .any)
        .matching(identifier: "algorithmDescriptionText").firstMatch
      XCTAssertTrue(description.waitForExistence(timeout: 10))
      let scroll = app.scrollViews["auditDetailScrollView"]
      XCTAssertLessThanOrEqual(description.frame.maxX, scroll.frame.maxX + 1,
                               "The long prose clips the narrow detail pane")
      let complexity = app.staticTexts["Complexity"]
      for _ in 0..<30 where !complexity.isHittable {
        scroll.swipeUp(velocity: .fast)
      }
      XCTAssertTrue(complexity.isHittable,
                    "Cannot scroll past the complete description for \(fixture.id)")
      let ending = app.staticTexts.matching(NSPredicate(
        format: "label CONTAINS %@", fixture.ending
      )).firstMatch
      XCTAssertTrue(ending.exists,
                    "The end of \(fixture.id)'s description is missing from the rendered page")
      let capture = XCTAttachment(screenshot: app.screenshot())
      capture.name = "long-description-end-\(fixture.id)"
      capture.lifetime = .keepAlways
      add(capture)
      app.terminate()
    }
  }

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
    assertLongFittedEquationCanBeScrolled(width: 900)
  }

  func testLongFittedEquationCanBeScrolledAtNarrowWidth() {
    assertLongFittedEquationCanBeScrolled(width: 360)
  }

  func testLongFittedEquationCanBeScrolledAtSmallestWidth() {
    assertLongFittedEquationCanBeScrolled(width: 320)
  }

  func testLongDetectedEquationCanBeScrolledAtSmallestWidth() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1", "UI_TEST_DETAIL_AUDIT_START": "22",
      "UI_TEST_DETAIL_AUDIT_WIDTH": "320", "UI_TEST_EQUATIONS_ONLY": "1"
    ]
    app.launch()
    XCTAssertEqual(app.staticTexts["auditAlgorithmID"].label, "bogosort")
    let equation = app.scrollViews["equationScroll-Detected"]
    XCTAssertTrue(equation.waitForExistence(timeout: 10))
    let before = equation.screenshot().pngRepresentation
    let initial = XCTAttachment(screenshot: app.screenshot())
    initial.name = "detected-equation-320-before"
    initial.lifetime = .keepAlways
    add(initial)
    equation.swipeLeft(velocity: .slow)
    XCTAssertNotEqual(equation.screenshot().pngRepresentation, before,
                      "The long detected equation did not reveal its remaining terms")
    let scrolled = XCTAttachment(screenshot: app.screenshot())
    scrolled.name = "detected-equation-320-after"
    scrolled.lifetime = .keepAlways
    add(scrolled)
  }

  private func assertLongFittedEquationCanBeScrolled(width: Int) {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1", "UI_TEST_DETAIL_AUDIT_START": "79",
      "UI_TEST_DETAIL_AUDIT_WIDTH": String(width)
    ]
    app.launch()
    XCTAssertEqual(app.staticTexts["auditAlgorithmID"].label, "introcirclesortrecursive")
    let description = app.descendants(matching: .any)
      .matching(identifier: "algorithmDescriptionText").firstMatch
    XCTAssertTrue(description.waitForExistence(timeout: 10), "detail content did not finish loading")
    let equation = app.scrollViews["equationScroll-Fitted (Used by App)"]
    XCTAssertTrue(equation.waitForExistence(timeout: 5))
    if width <= 360 {
      let detailScroll = app.scrollViews["auditDetailScrollView"]
      for _ in 0..<20 where !equation.isHittable {
        detailScroll.swipeUp(velocity: .slow)
      }
      XCTAssertTrue(equation.isHittable, "The fitted equation did not enter the narrow viewport")
    }
    let before = equation.screenshot().pngRepresentation
    let initial = XCTAttachment(screenshot: app.screenshot())
    initial.name = "fitted-equation-\(width)-before"
    initial.lifetime = .keepAlways
    add(initial)
    equation.swipeLeft(velocity: .slow)
    XCTAssertNotEqual(equation.screenshot().pngRepresentation, before,
                      "The long fitted equation did not reveal its remaining terms")
    let scrolled = XCTAttachment(screenshot: app.screenshot())
    scrolled.name = "fitted-equation-\(width)-after"
    scrolled.lifetime = .keepAlways
    add(scrolled)
  }

  private func audit(_ range: Range<Int>, width: Int = 900, prefix: String = "") {
    continueAfterFailure = false
    #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .portrait
    #endif
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1",
      "UI_TEST_DETAIL_AUDIT_START": String(range.lowerBound),
      "UI_TEST_DETAIL_AUDIT_WIDTH": String(width),
      "UI_TEST_EXPANDED_WIDTH": width == 360 ? "360" : ""
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
        if width == 360 {
          XCTAssertLessThanOrEqual(description.frame.maxX, scroll.frame.maxX + 1,
                                   "Description clips the narrow pane for \(algorithmID)")
          let grid = app.descendants(matching: .any)
            .matching(identifier: "complexityEquationGrid").firstMatch
          XCTAssertTrue(grid.exists)
          XCTAssertLessThanOrEqual(grid.frame.maxX, scroll.frame.maxX + 1,
                                   "Complexity equations clip the narrow pane for \(algorithmID)")
        }
        XCTAssertTrue(app.staticTexts["Description"].isHittable,
                      "Detail page did not reset to the top for \(algorithmID)")
        for label in ["Best Case", "Average Complexity", "Worst Case", "Space Complexity", "Implementation Complexity",
                      "Growth Model", "Fitted (Used by App)", "Big-O Correlation"] {
          XCTAssertTrue(app.staticTexts[label].exists, "Missing \(label) for \(algorithmID)")
        }
        let top = XCTAttachment(screenshot: app.screenshot())
        top.name = "\(prefix)\(String(format: "%03d", offset + 1))-\(algorithmID)-top"
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
        // Catalyst's wheel event path can trap with repeated narrow-pane scrolls. Use a drag
        // there; retain measured wheel steps for the wider layout where they are reliable.
        for _ in 0..<30 {
          if expandButton.isHittable,
             expandButton.frame.minY >= scroll.frame.minY + 24,
             expandButton.frame.maxY <= scroll.frame.maxY - 24 { break }
          #if targetEnvironment(macCatalyst)
          if width == 360 {
            if expandButton.frame.maxY > scroll.frame.maxY - 24 {
              scroll.swipeUp(velocity: .slow)
            } else {
              scroll.swipeDown(velocity: .slow)
            }
          } else {
            let delta = expandButton.frame.maxY > scroll.frame.maxY - 24 ? -150.0 : 150.0
            scroll.scroll(byDeltaX: 0, deltaY: delta)
          }
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
        bottom.name = "\(prefix)\(String(format: "%03d", offset + 1))-\(algorithmID)-charts"
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
        large.name = "\(prefix)\(String(format: "%03d", offset + 1))-\(algorithmID)-expanded"
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

/// Renders the shipping equation cells at a 320-point detail width. Omitting description prose
/// keeps all six equations in the first viewport, so every algorithm can be captured and reviewed.
@MainActor
final class AlgorithmEquationCorpusUITests: XCTestCase {
  func testSmoke() { audit(0..<2) }
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
      "UI_TEST_DETAIL_AUDIT_WIDTH": "320",
      "UI_TEST_EQUATIONS_ONLY": "1"
    ]
    app.launch()
    let scroll = app.scrollViews["auditDetailScrollView"]
    XCTAssertTrue(scroll.waitForExistence(timeout: 10))

    var seen = Set<String>()
    for offset in range {
      let id = app.staticTexts["auditAlgorithmID"]
      XCTAssertEqual(app.staticTexts["auditIndexLabel"].label, "\(offset + 1) of 196")
      let algorithmID = id.label
      XCTAssertTrue(seen.insert(algorithmID).inserted)
      let grid = app.descendants(matching: .any)
        .matching(identifier: "complexityEquationGrid").firstMatch
      XCTAssertTrue(grid.waitForExistence(timeout: 10), "Missing complexity grid for \(algorithmID)")
      XCTAssertGreaterThanOrEqual(grid.frame.minX, scroll.frame.minX - 1)
      XCTAssertLessThanOrEqual(grid.frame.maxX, scroll.frame.maxX + 1,
                               "Complexity grid clips the 320-point pane for \(algorithmID)")
      for label in ["Best Case", "Average Complexity", "Worst Case", "Space Complexity",
                    "Detected", "Fitted (Used by App)"] {
        XCTAssertTrue(app.staticTexts[label].exists, "Missing \(label) equation for \(algorithmID)")
      }
      XCTAssertTrue(app.staticTexts["Complexity"].isHittable)
      let capture = XCTAttachment(screenshot: app.screenshot())
      capture.name = "equations-320-\(String(format: "%03d", offset + 1))-\(algorithmID)"
      capture.lifetime = .keepAlways
      add(capture)
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

@MainActor
final class ExpandedBigONarrowInteractionUITests: XCTestCase {
  func testDenseChartFitsSelectsAndTogglesAtNarrowWidth() {
    continueAfterFailure = false
    #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .portrait
    #endif
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DETAIL_AUDIT": "1",
      "UI_TEST_DETAIL_AUDIT_WIDTH": "360",
      "UI_TEST_COMPACT_BIGO_ONLY": "1",
      "UI_TEST_EXPANDED_WIDTH": "360"
    ]
    app.launch()
    let compact = app.descendants(matching: .any)
      .matching(identifier: "bigOCorrelationChart").firstMatch
    XCTAssertTrue(compact.waitForExistence(timeout: 10))
    app.activateControlForUITest(app.buttons["Expand Chart"])
    let expanded = app.descendants(matching: .any)
      .matching(identifier: "bigOCorrelationExpandedChart").firstMatch
    XCTAssertTrue(expanded.waitForExistence(timeout: 10))
    XCTAssertGreaterThan(expanded.frame.width, 250)
    XCTAssertLessThanOrEqual(expanded.frame.width, 313)
    #if !targetEnvironment(macCatalyst)
    XCTAssertGreaterThanOrEqual(expanded.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(expanded.frame.maxX, app.frame.maxX)
    #endif
    let legend = app.descendants(matching: .any)
      .matching(identifier: "bigOReferenceLegend").firstMatch
    XCTAssertTrue(legend.exists)
    XCTAssertGreaterThanOrEqual(legend.frame.minX, expanded.frame.minX - 1)
    XCTAssertLessThanOrEqual(legend.frame.maxX, expanded.frame.maxX + 1)
    let individual = app.descendants(matching: .any)
      .matching(identifier: "Show Individual Runs").firstMatch
    XCTAssertTrue(individual.exists)
    XCTAssertLessThanOrEqual(individual.frame.maxX, expanded.frame.maxX + 1)

    XCTAssertGreaterThanOrEqual(expanded.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(expanded.frame.maxX, app.frame.maxX + 1)
    XCTAssertTrue(String(describing: expanded.value ?? "").contains("Observed mean"))

    let selected = app.staticTexts["bigOSelectedSize"]
    app.activateControlForUITest(app.buttons["Next Recorded Size"])
    XCTAssertTrue(selected.label.hasPrefix("Array Size "))
    let firstSelectedSize = selected.label
    app.typeKey("n", modifierFlags: [.command, .option])
    XCTAssertNotEqual(selected.label, firstSelectedSize,
      "Command-Option-N should inspect the next recorded size while the chart is open")
    let observed = app.staticTexts["bigOSelection.Observed"]
    XCTAssertTrue(observed.exists)
    XCTAssertTrue(app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Observed minimum:"))
      .firstMatch.exists)
    XCTAssertTrue(app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Observed maximum:"))
      .firstMatch.exists)
    let toggle = app.descendants(matching: .any)
      .matching(identifier: "bigOSeriesToggle.Observed").firstMatch
    XCTAssertTrue(toggle.exists)
    app.activateControlForUITest(toggle)
    XCTAssertFalse(observed.exists, "Hidden observed series remained in the selection")
    app.activateControlForUITest(toggle)
    XCTAssertTrue(observed.exists)
    app.activateControlForUITest(individual)
    XCTAssertTrue(expanded.exists)
    XCTAssertTrue(app.descendants(matching: .any)
      .matching(identifier: "bigOScatterLegend").firstMatch.exists)
    XCTAssertTrue(String(describing: expanded.value ?? "").contains("individual runs"))
    let capture = XCTAttachment(screenshot: app.screenshot())
    capture.name = "expanded-bigo-narrow-interactions"
    capture.lifetime = .keepAlways
    add(capture)
  }
}
