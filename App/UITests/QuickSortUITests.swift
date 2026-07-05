import XCTest

/// Phase 4's "does the whole idea actually work" checkpoint, proven by actually driving the app
/// rather than trusting a unit test: launch, navigate to the temporary debug entry point, and
/// confirm record -> replay -> draw produces a genuinely correctly-sorted result, not just "some
/// completion event fired." A `Canvas` has no discrete accessible bars to individually inspect, so
/// `SortView` exposes `sortStatusLabel`'s accessibility value as the correctness signal — the app
/// itself checks `frame.values == frame.values.sorted()` and reports the answer.
final class QuickSortUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testQuickSortEndToEndProducesACorrectlySortedResult() throws {
        let app = XCUIApplication()
        app.launch()

        let debugLink = app.buttons["debugQuickSortLink"]
        XCTAssertTrue(debugLink.waitForExistence(timeout: 5), "debug entry point never appeared")
        debugLink.tap()

        let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), "visualization canvas never appeared — recording/replay wiring is broken")

        let statusLabel = app.staticTexts["sortStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared")

        let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: terminalState, object: statusLabel)
        let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 30)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "quicksort-final-state"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertEqual(result, .completed, "sort never reached a terminal state within 30s — replay likely hung")
        XCTAssertEqual(
            statusLabel.value as? String, "sorted",
            "algorithm completed but the app's own sortedness check reported failure"
        )
    }

    func testDebugEntryPointIsReachableFromLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Sort Symphony v2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["debugQuickSortLink"].exists)
    }
}
