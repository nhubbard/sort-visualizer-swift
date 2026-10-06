import XCTest

@MainActor
final class NavigationAccessibilityUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testTransportAnnouncesStateAndAccessibleActionsWork() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let play = app.buttons["runControlPlayPauseButton"]
    XCTAssertTrue(play.waitForExistence(timeout: 10))
    app.activateControlForUITest(play)
    let jumpStart = app.buttons["runControlJumpToStartButton"]
    app.activateControlForUITest(jumpStart)
    XCTAssertEqual(play.label, "Play")

    let transport = [
      ("runControlJumpToStartButton", "Jump to Start"),
      ("runControlStepBackButton", "Step Back"),
      ("runControlPlayPauseButton", "Play"),
      ("runControlStepForwardButton", "Step Forward"),
      ("runControlJumpToEndButton", "Jump to End"),
    ]
    for (id, label) in transport {
      XCTAssertEqual(app.buttons[id].label, label)
    }

    let visibleTransportIDs = app.buttons.allElementsBoundByIndex.map(\.identifier)
      .filter { $0.hasPrefix("runControl") && transport.map(\.0).contains($0) }
    XCTAssertEqual(visibleTransportIDs, transport.map(\.0),
      "the accessibility tree should follow the visual transport order")

    let scrub = app.sliders["runControlScrubSlider"]
    XCTAssertEqual(scrub.label, "Playback position")
    #if !targetEnvironment(macCatalyst)
      XCTAssertTrue((scrub.value as? String)?.contains("Operation 0 of ") == true)
    #endif
    let size = app.buttons["runControlSizeButton"]
    XCTAssertEqual(size.label, "Array Size")
    XCTAssertEqual(size.value as? String, "24 items")
    let speed = app.buttons["runControlSpeedButton"]
    XCTAssertEqual(speed.label, "Playback Speed")
    XCTAssertEqual(speed.value as? String, "1 ops per second")

    app.activateControlForUITest(app.buttons["runControlStepForwardButton"])
    #if !targetEnvironment(macCatalyst)
      XCTAssertTrue((scrub.value as? String)?.hasPrefix("Operation 1 of ") == true)
    #endif
    XCTAssertTrue(jumpStart.isEnabled)
    app.activateControlForUITest(jumpStart)
    XCTAssertFalse(jumpStart.isEnabled)

    let sound = app.buttons["runControlSoundToggle"]
    let oldSoundLabel = sound.label
    XCTAssertTrue(["Mute", "Unmute"].contains(oldSoundLabel))
    app.activateControlForUITest(sound)
    XCTAssertNotEqual(sound.label, oldSoundLabel)
  }

  func testHomeAndSortSupportDynamicType() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    XCTAssertTrue(app.buttons["SORT SYMPHONY"].waitForExistence(timeout: 5))
    try app.performAccessibilityAudit(for: .dynamicType)

    app.tapSidebarLink("algorithmLink.quicksort")
    XCTAssertTrue(app.sliders["runControlScrubSlider"].waitForExistence(timeout: 10))
    try app.performAccessibilityAudit(for: .dynamicType)
  }
}
