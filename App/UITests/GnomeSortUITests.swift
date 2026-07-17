import XCTest

/// Phase 7 batch checkpoint: proves that at least one of the newly-ported algorithms actually
/// renders and sorts correctly end-to-end in the running app, not just in the unit-level
/// `BundledContentCorrectnessTests`. Mirrors `QuickSortUITests`'s approach.
@MainActor
final class GnomeSortUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    // Now that portrait is a genuinely supported orientation (not just coerced to landscape by
    // iOS), the simulator's own default boot orientation (portrait) would otherwise leak into
    // this test unpinned — see `ScreenshotUITests`' identical rationale.
    XCUIDevice.shared.orientation = .landscapeLeft
  }

  func testGnomeSortEndToEndProducesACorrectlySortedResult() throws {
    let app = XCUIApplication()
    // Small, fast array size — AppSettings.defaultArraySize's real default (256) would make
    // Gnome Sort's O(n^2) tape take minutes, which is correct/expected in the real app but
    // impractical for a UI test's timeout.
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let sidebarLink = app.revealSidebarLink("algorithmLink.gnomesort")
    XCTAssertTrue(
      sidebarLink.waitForExistence(timeout: 5), "Gnome Sort sidebar link never appeared")
    sidebarLink.tap()

    let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas")
      .firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 5), "visualization canvas never appeared")

    let statusLabel = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared")

    let midFlightScreenshot = XCTAttachment(screenshot: app.screenshot())
    midFlightScreenshot.name = "gnomesort-mid-flight-state"
    midFlightScreenshot.lifetime = .keepAlways
    add(midFlightScreenshot)

    // Gnome Sort's O(n^2) tape has far more recorded operations than Quick Sort's for the
    // same array size, so at the app's fixed default playback speed it genuinely needs more
    // real time to finish — not a sign of a hang, unlike the shorter timeout used for
    // Quick Sort's own end-to-end test. Also budgets for RecordingEngine's primary/secondary
    // auto-retraction (every compare/swap past the first now emits 2 extra raw tape entries
    // to un-highlight the previous pair), which inflates total tape length — and therefore
    // real playback time at a fixed ops/sec — by roughly 5/3 versus before that fix.
    let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
    let reachedTerminalState = XCTNSPredicateExpectation(
      predicate: terminalState, object: statusLabel)
    let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 150)

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "gnomesort-final-state"
    screenshot.lifetime = .keepAlways
    add(screenshot)

    XCTAssertEqual(
      result, .completed, "sort never reached a terminal state within 150s — replay likely hung")
    XCTAssertEqual(
      statusLabel.value as? String, "sorted",
      "algorithm completed but the app's own sortedness check reported failure"
    )
  }
}
