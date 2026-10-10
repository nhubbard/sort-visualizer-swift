import XCTest

@MainActor
final class NavigationContentUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testHomeExampleOpensSortAndHelpExplainsControls() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1",
      "UI_TEST_DISCOVERY_TIPS": "1",
    ]
    app.launch()

    let example = app.buttons["homeTryQuickSortButton"]
    XCTAssertTrue(example.waitForExistence(timeout: 5))
    XCTAssertEqual(example.label, "Try Quick Sort")
    app.activateControlForUITest(example)

    XCTAssertTrue(app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch.waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["sortDetailsScrollCue"].exists)
    let playbackTip = app.descendants(matching: .any)
      .matching(identifier: "sortPlaybackTip").firstMatch
    XCTAssertTrue(playbackTip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Explore one step at a time"].exists)
    let help = app.buttons["How to Use"]
    XCTAssertEqual(help.label, "How to Use")
    app.activateControlForUITest(help)
    XCTAssertTrue(app.staticTexts["Use Play to watch the recording. Pause and use Step Forward or Step Back to inspect one operation at a time."].waitForExistence(timeout: 5))
    app.activateControlForUITest(app.buttons["sortHelpDoneButton"])
    XCTAssertTrue(help.waitForExistence(timeout: 5))
    app.activateControlForUITest(app.buttons["runControlStepForwardButton"])
    let presentationTip = app.descendants(matching: .any)
      .matching(identifier: "sortPresentationTip").firstMatch
    XCTAssertTrue(presentationTip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Change the view"].exists)
    app.activateControlForUITest(app.buttons["runControlSizeButton"])
    XCTAssertTrue(app.buttons["runControlSizeChip-16"].waitForExistence(timeout: 5))
    let seekingTip = app.descendants(matching: .any)
      .matching(identifier: "sortSeekingTip").firstMatch
    XCTAssertTrue(seekingTip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Revisit any operation"].exists)
    app.activateControlForUITest(app.buttons["runControlJumpToEndButton"])
    assertDisappears(seekingTip)

    app.terminate()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")
    XCTAssertTrue(app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch.waitForExistence(timeout: 10))
    XCTAssertFalse(app.staticTexts["Explore one step at a time"].exists)
    XCTAssertFalse(app.staticTexts["Change the view"].exists)
    XCTAssertFalse(app.staticTexts["Revisit any operation"].exists)
  }

  func testVideoControlsExpandInRunBarWithoutMovingStatusOrHelp() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1"]
    app.launch()
    app.activateControlForUITest(app.buttons["homeTryQuickSortButton"])

    let status = app.staticTexts["sortStatusLabel"]
    let cue = app.staticTexts["sortDetailsScrollCue"]
    let help = app.buttons["How to Use"]
    let video = app.buttons["runControlVideoButton"]
    XCTAssertTrue(status.waitForExistence(timeout: 10))
    XCTAssertTrue(cue.exists)
    XCTAssertEqual(help.label, "How to Use")
    XCTAssertTrue(video.exists)
    XCTAssertFalse(app.buttons["liveRecordingStartButton"].exists)

    app.activateControlForUITest(video)
    XCTAssertTrue(app.buttons["liveRecordingStartButton"].waitForExistence(timeout: 5))
    XCTAssertTrue(status.exists)
    XCTAssertTrue(cue.exists)
    XCTAssertTrue(help.exists)
    app.activateControlForUITest(video)
    XCTAssertFalse(app.buttons["liveRecordingStartButton"].exists)
  }

  func testCatalogTipAppearsBeforeSelectionAndDismissesAfterBrowsing() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_DISCOVERY_TIPS": "1"]
    app.launch()

    let tip = app.descendants(matching: .any)
      .matching(identifier: "catalogDiscoveryTip").firstMatch
    XCTAssertTrue(tip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Find an algorithm"].exists)
    app.tapSidebarLink("algorithmLink.quicksort")
    assertDisappears(tip)
  }

  func testSettingsTipExplainsDefaultsAndDismissesAfterChange() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_DISCOVERY_TIPS": "1", "UI_TEST_FRESH_SETTINGS": "1"]
    app.launch()
    app.openSettingsForUITest()

    let tip = app.descendants(matching: .any)
      .matching(identifier: "settingsDiscoveryTip").firstMatch
    XCTAssertTrue(tip.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Set defaults for future sorts"].exists)
    app.activateControlForUITest(app.segmentedControls["pacingModePicker"].buttons["Fixed Duration"])
    assertDisappears(tip)
  }

  func testCodeAndRecordedChartTipsAppearOnlyWithRelevantContent() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_DISCOVERY_TIPS": "1", "UI_TEST_HISTORY_SCENARIO": "populated",
      "UI_TEST_ARRAY_SIZE": "16", "UI_TEST_PLAYBACK_SPEED": "100000",
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let scroll = app.scrollViews["algorithmDetailScrollView"]
    let chartTip = app.descendants(matching: .any)
      .matching(identifier: "sortRecordedChartTip").firstMatch
    for _ in 0..<12 where !chartTip.isHittable { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(chartTip.isHittable)
    XCTAssertTrue(app.staticTexts["Compare your recorded runs"].exists)
    app.activateControlForUITest(app.buttons["bigOExpandChartButton"])
    XCTAssertTrue(app.descendants(matching: .any)
      .matching(identifier: "bigOCorrelationExpandedChart").firstMatch.waitForExistence(timeout: 5))
    app.activateControlForUITest(app.buttons["Done"])

    let codeTip = app.descendants(matching: .any)
      .matching(identifier: "sortCodeTip").firstMatch
    for _ in 0..<12 where !codeTip.isHittable { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(codeTip.isHittable)
    XCTAssertTrue(app.staticTexts["Explore the implementation"].exists)
    app.activateControlForUITest(app.buttons["copyAlgorithmCode"])
    assertDisappears(codeTip)
  }

  private func assertDisappears(_ element: XCUIElement, file: StaticString = #filePath,
                                line: UInt = #line) {
    let gone = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == false"), object: element)
    XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 5), .completed,
                   "Tip should dismiss after the related action", file: file, line: line)
  }

  func testEmptySearchExplainsTheStateAndDetailShowsSelectedContent() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let search = app.searchFields["Search"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    app.activateControlForUITest(search)
    search.typeText("no algorithm has this name 476829")
    XCTAssertTrue(app.staticTexts["No Matching Algorithms"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Try another name or category."].exists)
    XCTAssertFalse(app.buttons["algorithmLink.quicksort"].exists)

    app.terminate()
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")
    let description = app.descendants(matching: .any)
      .matching(identifier: "algorithmDescriptionText").firstMatch
    XCTAssertTrue(description.waitForExistence(timeout: 10), "Quick Sort description did not load")
    XCTAssertTrue(description.label.localizedCaseInsensitiveContains("Quick Sort"),
                  "The selected algorithm's description is missing: \(description.label)")
    XCTAssertTrue(app.staticTexts["Best Case"].exists)
    XCTAssertTrue(app.staticTexts["Worst Case"].exists)
    XCTAssertTrue(app.staticTexts["Big-O Correlation"].exists)

    let scroll = app.scrollViews["algorithmDetailScrollView"]
    let languagePicker = app.segmentedControls["codeLanguagePicker"]
    for _ in 0 ..< 12 where !languagePicker.exists { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(languagePicker.exists, "Selected algorithm's reference implementations are missing")
    XCTAssertTrue(languagePicker.buttons["Swift"].exists)
  }
}
