import XCTest

@MainActor
final class TeachingGraphUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  func testQuickSortGraphNavigatesPivotDecisions() {
    let app = openGraph(algorithmID: "quicksort")
    let explanation = app.staticTexts["teachingGraphExplanation"]
    let next = app.buttons["teachingGraphNextButton"]
    let previous = app.buttons["teachingGraphPreviousButton"]

    XCTAssertTrue(explanation.label.contains("graph begins after the shuffle")
      || explanation.label.contains("first decision"))
    XCTAssertFalse(previous.isEnabled)
    app.activateControlForUITest(next)
    XCTAssertTrue(explanation.label.contains("pivot"))
    XCTAssertTrue(previous.isEnabled == false)
    XCTAssertEqual(app.staticTexts["sortStatusLabel"].value as? String, "reviewing")
    app.activateControlForUITest(next)
    XCTAssertTrue(previous.isEnabled)
    app.activateControlForUITest(previous)
    XCTAssertTrue(explanation.label.contains("pivot"))
  }

  func testMergeSortGraphShowsBufferMovement() {
    let app = openGraph(algorithmID: "mergesort")
    let explanation = app.staticTexts["teachingGraphExplanation"]
    let next = app.buttons["teachingGraphNextButton"]
    var reachedBuffer = false
    for _ in 0..<20 {
      app.activateControlForUITest(next)
      if explanation.label.contains("buffer") {
        reachedBuffer = true
        break
      }
    }
    XCTAssertTrue(reachedBuffer, "Merge Sort should expose a source-to-buffer transition")
  }

  private func openGraph(algorithmID: String) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "16", "UI_TEST_PLAYBACK_SPEED": "1",
      "UI_TEST_DISCOVERY_TIPS": "1",
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.\(algorithmID)")
    let canvas = app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 10))
    let jump = app.buttons["runControlJumpToStartButton"]
    if jump.isEnabled {
      app.activateControlForUITest(jump)
    } else {
      let transport = app.buttons["runControlPlayPauseButton"]
      if transport.label == "Pause" { app.activateControlForUITest(transport) }
    }

    let scroll = app.scrollViews["algorithmDetailScrollView"]
    let disclosure = app.descendants(matching: .any)
      .matching(identifier: "teachingGraphDisclosure").firstMatch
    for _ in 0..<10 where !disclosure.isHittable { scroll.swipeUp(velocity: .slow) }
    XCTAssertTrue(disclosure.isHittable)
    app.activateControlForUITest(disclosure)
    XCTAssertTrue(app.staticTexts["teachingGraphExplanation"].waitForExistence(timeout: 5))
    return app
  }
}
