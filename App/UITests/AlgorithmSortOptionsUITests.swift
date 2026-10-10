import XCTest

@MainActor
final class AlgorithmSortOptionsUITests: XCTestCase {
  func testSortOptionsExposeTheValuesUsedToOrderAlgorithms() {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launch()

    // The SF Symbol varies by algorithm, but the row's accessible name is the algorithm name.
    // A separate icon announcement would add noise without conveying another property.
    let firstAlgorithm = app.buttons["algorithmLink.threesmoothcombsortiterative"]
    XCTAssertTrue(firstAlgorithm.waitForExistence(timeout: 5))
    XCTAssertEqual(firstAlgorithm.label, "3-Smooth Comb Sort (Iterative)")

    #if targetEnvironment(macCatalyst)
      let menu = app.menuButtons["Sort"]
    #else
      let menu = app.buttons["algorithmSortMenu"]
    #endif
    XCTAssertTrue(menu.waitForExistence(timeout: 5))
    app.activateControlForUITest(menu)
    selectSortOption("Implementation Complexity", in: app)
    XCTAssertTrue(app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Complexity:")
    ).firstMatch.waitForExistence(timeout: 5))

    app.activateControlForUITest(menu)
    selectSortOption("Estimated Speed", in: app)
    let estimate = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS %@ OR label BEGINSWITH %@", "ops at n=", "N/A above n=")
    ).firstMatch
    XCTAssertTrue(estimate.waitForExistence(timeout: 5))

    app.activateControlForUITest(menu)
    selectSortOption("Name", in: app)
    XCTAssertFalse(app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Complexity:")
    ).firstMatch.exists)
  }

  private func selectSortOption(_ title: String, in app: XCUIApplication) {
    #if targetEnvironment(macCatalyst)
      let item = app.menuItems[title]
      XCTAssertTrue(item.waitForExistence(timeout: 5), app.debugDescription)
      item.click()
    #else
      app.buttons[title].tap()
    #endif
  }
}

@MainActor
final class FullSweepConfirmationUITests: XCTestCase {
  func testFullSweepCancelAndConfirmGateTheRun() {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launch()

    #if targetEnvironment(macCatalyst)
      let sweepButton = app.buttons["Start Full Sweep"]
    #else
      let sweepButton = app.buttons["fullSweepButton"]
    #endif
    XCTAssertTrue(sweepButton.waitForExistence(timeout: 5))
    app.activateControlForUITest(sweepButton)
    #if targetEnvironment(macCatalyst)
      // Catalyst presents this SwiftUI confirmation as a native modal outside the app's
      // queryable button tree; the underlying application becomes disabled while it is open.
      XCTAssertFalse(app.isEnabled, "the confirmation should block the underlying window")
    #else
      let confirmation = app.buttons["fullSweepConfirmButton"]
      XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
    #endif
    XCTAssertFalse(app.staticTexts["fullSweepProgressLabel"].exists)

    app.typeKey(.escape, modifierFlags: [])
    XCTAssertFalse(app.staticTexts["fullSweepProgressLabel"].exists)

    app.terminate()
    app.launch()
    XCTAssertFalse(app.staticTexts["fullSweepProgressLabel"].exists)
    #if targetEnvironment(macCatalyst)
      let confirmTrigger = app.buttons["Start Full Sweep"]
    #else
      let confirmTrigger = app.buttons["fullSweepButton"]
    #endif
    XCTAssertTrue(confirmTrigger.waitForExistence(timeout: 5))
    app.activateControlForUITest(confirmTrigger)
    #if targetEnvironment(macCatalyst)
      // The native sheet is outside XCTest's app button tree and initially focuses Cancel.
      // Tab moves focus to Start/Resume Full Sweep; Space activates that focused action.
      app.typeKey(.tab, modifierFlags: [])
      app.typeKey(.space, modifierFlags: [])
    #else
      let confirm = app.buttons.matching(identifier: "fullSweepConfirmButton").firstMatch
      XCTAssertTrue(confirm.waitForExistence(timeout: 5))
      confirm.tap()
    #endif
    let progress = app.staticTexts["fullSweepProgressLabel"]
    XCTAssertTrue(progress.waitForExistence(timeout: 10), "confirming should start the sweep")
    XCTAssertFalse(app.buttons["automationStopButton"].exists)
    #if targetEnvironment(macCatalyst)
      XCTAssertTrue(app.buttons["Stop Full Sweep"].exists)
    #else
      XCTAssertEqual(app.buttons["fullSweepButton"].label, "Stop Full Sweep")
    #endif
    let stop = app.buttons["fullSweepStopButton"]
    XCTAssertTrue(stop.waitForExistence(timeout: 5))
    app.activateControlForUITest(stop)
    app.terminate()
  }
}

@MainActor
final class FullSweepPersistenceUITests: XCTestCase {
  private struct Audit {
    let running: Bool
    let completed: Int
    let total: Int
    let current: String
    let rows: [String]
  }

  private func audit(_ element: XCUIElement) -> Audit? {
    guard let raw = element.value as? String else { return nil }
    let fields = raw.components(separatedBy: "|")
    guard fields.count == 5, let completed = Int(fields[1]), let total = Int(fields[2]) else {
      return nil
    }
    return Audit(
      running: fields[0] == "true", completed: completed, total: total, current: fields[3],
      rows: fields[4].isEmpty ? [] : fields[4].components(separatedBy: ";"))
  }

  private func waitForAudit(
    _ element: XCUIElement, timeout: TimeInterval = 60, matching predicate: (Audit) -> Bool
  ) -> Audit? {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let state = audit(element), predicate(state) { return state }
      Thread.sleep(forTimeInterval: 0.2)
    }
    XCTFail("Coverage log never reached expected state: \(element.value ?? "missing")")
    return nil
  }

  private func startSweep(in app: XCUIApplication) {
    #if targetEnvironment(macCatalyst)
      app.buttons["Start Full Sweep"].click()
      app.typeKey(.tab, modifierFlags: [])
      app.typeKey(.space, modifierFlags: [])
    #else
      app.buttons["fullSweepButton"].tap()
      app.buttons.matching(identifier: "fullSweepConfirmButton").firstMatch.tap()
    #endif
  }

  func testFullSweepStopsPersistsAndResumesEveryCombinationExactlyOnce() {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    let common = [
      "UI_TEST_AUTOMATION_ALGORITHMS": "threesmoothcombsortiterative",
      "UI_TEST_AUTOMATION_SHUFFLES": "ascending,random",
      "UI_TEST_AUTOMATION_VISUALIZERS": "bargraph,rainbow",
      "UI_TEST_FULL_SWEEP_SIZE": "32",
      "UI_TEST_FULL_SWEEP_LOG_NAME": UUID().uuidString,
      "UI_TEST_ARRAY_SIZE": "32",
    ]
    app.launchEnvironment = common.merging(["UI_TEST_PLAYBACK_SPEED": "1"]) { _, new in new }
    app.launch()
    let probe = app.staticTexts["coverageSweepLogProbe"]
    XCTAssertNotNil(waitForAudit(probe, matching: { !$0.running && $0.total == 4 && $0.rows.isEmpty }))
    startSweep(in: app)
    XCTAssertNotNil(waitForAudit(probe, matching: { $0.running && !$0.current.isEmpty }))
    let stop = app.buttons["fullSweepStopButton"]
    XCTAssertTrue(stop.waitForExistence(timeout: 5))
    XCTAssertEqual(app.buttons.matching(identifier: "fullSweepStopButton").count, 1)
    XCTAssertFalse(app.buttons["automationStopButton"].exists)
    app.activateControlForUITest(stop)
    let stopped = waitForAudit(probe, matching: { !$0.running && $0.completed == 0 })
    XCTAssertTrue(stopped?.rows.isEmpty ?? false)

    app.terminate()
    app.launchEnvironment = common.merging(["UI_TEST_PLAYBACK_SPEED": "1000"]) { _, new in new }
    app.launch()
    let restored = waitForAudit(probe, matching: { !$0.running && $0.completed == 0 })
    XCTAssertEqual(restored?.rows, stopped?.rows)
    startSweep(in: app)
    let finished = waitForAudit(probe, timeout: 90, matching: { !$0.running && $0.completed == 4 })
    let expected: Set<String> = [
      "threesmoothcombsortiterative,ascending,bargraph",
      "threesmoothcombsortiterative,ascending,rainbow",
      "threesmoothcombsortiterative,random,bargraph",
      "threesmoothcombsortiterative,random,rainbow",
    ]
    XCTAssertEqual(finished?.total, 4)
    XCTAssertEqual(finished?.rows.count, 4, "the append-only log must contain no duplicate rows")
    XCTAssertEqual(Set(finished?.rows ?? []), expected)
    XCTAssertFalse(app.staticTexts["fullSweepProgressLabel"].exists)
  }
}

@MainActor
final class AutomationJourneyUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  private func waitForValue(
    _ element: XCUIElement, timeout: TimeInterval = 60,
    matching predicate: (String) -> Bool
  ) -> String? {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let value = element.value as? String, predicate(value) { return value }
      Thread.sleep(forTimeInterval: 0.2)
    }
    XCTFail("Automation probe never reached expected state: \(element.value ?? "missing")")
    return nil
  }

  #if !targetEnvironment(macCatalyst)
  func testShowcaseStopsAndThenTraversesAlphabeticalAlgorithms() {
    let app = XCUIApplication()
    let common = [
      "UI_TEST_AUTOMATION_ALGORITHMS": "quicksort,threesmoothcombsortiterative",
      "UI_TEST_AUTOMATION_SHUFFLES": "ascending,random",
      "UI_TEST_AUTOMATION_VISUALIZERS": "bargraph,rainbow",
      "UI_TEST_AUTOMATION_AUDIT": "1",
      "UI_TEST_DETERMINISTIC_REPLAY": "1",
    ]
    app.launchEnvironment = common.merging([
      "UI_TEST_SHOWCASE_SIZE": "128", "UI_TEST_PLAYBACK_SPEED": "30",
    ]) { _, new in new }
    app.launch()
    let showcase = app.buttons["showcaseButton"]
    app.activateControlForUITest(showcase)
    app.buttons.matching(identifier: "showcaseConfirmButton").firstMatch.tap()
    let probe = app.staticTexts["showcaseAuditProbe"]
    XCTAssertNotNil(waitForValue(probe, matching: { $0 == "true|" }))
    XCTAssertEqual(showcase.label, "Stop Showcase")
    XCTAssertTrue(app.buttons["showcaseStopButton"].exists)
    XCTAssertFalse(app.buttons["automationStopButton"].exists)
    XCTAssertFalse(app.buttons["sidebarCategory.all"].isEnabled)
    XCTAssertFalse(app.buttons["algorithmLink.threesmoothcombsortiterative"].isEnabled)
    app.activateControlForUITest(app.buttons["showcaseStopButton"])
    XCTAssertNotNil(waitForValue(probe, matching: { $0 == "false|" }))
    XCTAssertFalse(app.staticTexts["showcaseProgressLabel"].exists)
    XCTAssertTrue(app.buttons["sidebarCategory.all"].isEnabled)

    app.terminate()
    app.launchEnvironment = common.merging([
      "UI_TEST_SHOWCASE_SIZE": "16", "UI_TEST_PLAYBACK_SPEED": "1000",
    ]) { _, new in new }
    app.launch()
    app.activateControlForUITest(showcase)
    app.buttons.matching(identifier: "showcaseConfirmButton").firstMatch.tap()
    let completed = waitForValue(probe, matching: {
      $0.hasPrefix("false|") && $0.components(separatedBy: ";").count == 2
    })
    let rows = completed?.components(separatedBy: "|").last?
      .components(separatedBy: ";").map { $0.components(separatedBy: ",") } ?? []
    XCTAssertEqual(rows.map { $0.first ?? "" }, ["threesmoothcombsortiterative", "quicksort"])
    XCTAssertEqual(Set(rows.compactMap { $0.count == 3 ? $0[1] : nil }), ["ascending", "random"])
    XCTAssertEqual(Set(rows.compactMap { $0.count == 3 ? $0[2] : nil }), ["bargraph", "rainbow"])
    XCTAssertFalse(app.staticTexts["showcaseProgressLabel"].exists)
  }
  #endif
}
