import XCTest

@MainActor
final class AlgorithmSortOptionsUITests: XCTestCase {
  func testSortOptionsExposeTheValuesUsedToOrderAlgorithms() {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
    let app = XCUIApplication()
    app.launch()

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
      let sweepButton = app.buttons["Checklist with checkmarks"]
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
      let confirmTrigger = app.buttons["Checklist with checkmarks"]
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
    let stop = app.buttons["fullSweepStopButton"]
    XCTAssertTrue(stop.waitForExistence(timeout: 5))
    app.activateControlForUITest(stop)
    app.terminate()
  }
}
