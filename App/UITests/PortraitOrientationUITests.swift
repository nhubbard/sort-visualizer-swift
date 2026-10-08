import XCTest

/// Portrait is now a genuinely declared, supported orientation (see `Project.swift`'s
/// `UISupportedInterfaceOrientations` — `UIRequiresFullScreen` is gone since Apple has announced
/// it'll stop being honored). Every other functional UI test pins `.landscapeLeft` explicitly
/// (`ScreenshotUITests`' rationale) to keep validating the primary orientation unchanged; this is
/// the one test that deliberately runs in `.portrait` instead, to prove the narrower width doesn't
/// break navigation, `RunControlBar`, or `AlgorithmDetailSection`.
@MainActor
final class PortraitOrientationUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    #if targetEnvironment(macCatalyst)
      throw XCTSkip("Portrait device orientation does not apply to Mac Catalyst")
    #else
      XCUIDevice.shared.orientation = .portrait
    #endif
  }

  func testSortingAlgorithmIsFullyUsableInPortrait() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1000"]
    app.launch()

    // The portrait check is about layout and navigation, not any specific algorithm. Pick a
    // visible first-row algorithm: swiping the long content list to Quick Sort can jump past its
    // virtualized row at this width and fail before the portrait layout is actually exercised.
    let firstAlgorithm = app.buttons["algorithmLink.threesmoothcombsortiterative"]
    XCTAssertTrue(firstAlgorithm.waitForExistence(timeout: 5))
    firstAlgorithm.tap()

    let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas")
      .firstMatch
    XCTAssertTrue(
      canvas.waitForExistence(timeout: 5), "visualization canvas never appeared in portrait")

    let statusLabel = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(
      statusLabel.waitForExistence(timeout: 5), "status label never appeared in portrait")

    // The transport and secondary controls occupy separate rows in portrait, while the stats
    // caption can stack. Confirm the controls remain reachable at this width.
    let playPauseButton = app.buttons["runControlPlayPauseButton"]
    XCTAssertTrue(
      playPauseButton.waitForExistence(timeout: 5), "play/pause button not reachable in portrait")
    let automatorButton = app.buttons["runControlAutomatorButton"]
    XCTAssertTrue(automatorButton.exists, "automator menu button not reachable in portrait")

    let terminalPredicate = NSPredicate(
      format: "value == %@ OR value == %@", "sorted", "sort-failed")
    let reachedTerminal = XCTNSPredicateExpectation(
      predicate: terminalPredicate, object: statusLabel)
    XCTAssertEqual(
      XCTWaiter().wait(for: [reachedTerminal], timeout: 60), .completed,
      "sort never reached a terminal state in portrait — replay likely hung")
    XCTAssertEqual(
      statusLabel.value as? String, "sorted",
      "sort completed but produced an incorrect result in portrait")

    // AlgorithmDetailSection stacks Description above Complexity below its width threshold —
    // confirms the stacked layout still renders (not just the wide one), reachable by scrolling.
    let descriptionHeading = app.staticTexts["Description"]
    for _ in 0..<10 where !descriptionHeading.exists {
      app.swipeUp()
    }
    XCTAssertTrue(
      descriptionHeading.exists,
      "AlgorithmDetailSection's Description heading never became reachable in portrait")
    let description = app.descendants(matching: .any)
      .matching(identifier: "algorithmDescriptionText").firstMatch
    XCTAssertTrue(description.waitForExistence(timeout: 10),
                  "The selected algorithm's description did not load in portrait")
    XCTAssertGreaterThan(description.label.count, 80,
                         "Portrait detail shows a heading without substantive description content")

    app.terminate()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "256", "UI_TEST_PLAYBACK_SPEED": "30"]
    app.launch()
  }

  func testCatalogBadgesRemainUnderstandableInPortrait() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let menu = app.buttons["algorithmSortMenu"]
    XCTAssertTrue(menu.waitForExistence(timeout: 5))
    menu.tap()
    app.buttons["Estimated Speed"].tap()

    let algorithm = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH %@", "algorithmLink.")
    ).firstMatch
    XCTAssertTrue(algorithm.waitForExistence(timeout: 5))
    XCTAssertFalse(algorithm.label.isEmpty)
    let estimate = algorithm.value as? String ?? ""
    XCTAssertTrue(estimate.contains("ops at n=") || estimate.contains("N/A above n="),
      "The badge should remain available as an accessibility value: \(estimate)")

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "portrait-estimated-speed-catalog"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}
