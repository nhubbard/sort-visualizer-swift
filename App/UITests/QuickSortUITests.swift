import XCTest

/// Phase 4's "does the whole idea actually work" checkpoint, proven by actually driving the app
/// rather than trusting a unit test: launch, navigate to Quick Sort via the real, data-driven
/// sidebar (Phase 9 — `algorithmLink.quicksort`, not a temporary debug link), and confirm
/// record -> replay -> draw produces a genuinely correctly-sorted result, not just "some
/// completion event fired." A `Canvas` has no discrete accessible bars to individually inspect, so
/// `SortView` exposes `sortStatusLabel`'s accessibility value as the correctness signal — the app
/// itself checks `frame.values == frame.values.sorted()` and reports the answer.
final class QuickSortUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testQuickSortEndToEndProducesACorrectlySortedResult() throws {
        let app = XCUIApplication()
        // Small, fast array size — AppSettings.defaultArraySize's real default (256) is
        // deliberately large and would make even Quick Sort's own timeout unreliable.
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        let sidebarLink = app.revealSidebarLink("algorithmLink.quicksort")
        XCTAssertTrue(sidebarLink.waitForExistence(timeout: 5), "Quick Sort sidebar link never appeared")
        sidebarLink.tap()

        let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5),
            "visualization canvas never appeared — recording/replay wiring is broken")

        let statusLabel = app.staticTexts["sortStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared")

        // Phase 6's checkpoint: a shuffle now plays before the sort, as part of the same
        // recorded/visualized tape. Grab a mid-flight screenshot to prove it's actually visible,
        // not just structurally present in the tape.
        let midFlightScreenshot = XCTAttachment(screenshot: app.screenshot())
        midFlightScreenshot.name = "quicksort-mid-flight-state"
        midFlightScreenshot.lifetime = .keepAlways
        add(midFlightScreenshot)

        // 60s (not 30s): RecordingEngine's primary/secondary auto-retraction (every compare/swap
        // past the first emits 2 extra raw tape entries un-highlighting the previous pair)
        // inflates total tape length, and therefore real playback time at a fixed ops/sec, by
        // roughly 5/3 versus before that fix.
        let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: terminalState, object: statusLabel)
        let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 60)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "quicksort-final-state"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertEqual(result, .completed, "sort never reached a terminal state within 60s — replay likely hung")
        XCTAssertEqual(
            statusLabel.value as? String, "sorted",
            "algorithm completed but the app's own sortedness check reported failure"
        )
    }

    func testSidebarIsReachableFromLaunchAndDataDriven() throws {
        let app = XCUIApplication()
        // Small, fast array size — AppSettings.defaultArraySize's real default (256) is
        // deliberately large and would make even Quick Sort's own timeout unreliable.
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Sort Symphony v2"].waitForExistence(timeout: 5))
        // Proves Phase 9's actual claim: the sidebar is generated from AlgorithmRegistry, not a
        // hand-maintained list — Quick Sort (.quick) and Bubble Sort (.exchange) both being
        // present confirms category sectioning works, not just a single flat list. Checked nearer
        // (`.exchange`, 3rd category) before farther (`.quick`, 9th) — scrolling for the farther
        // one afterward can recycle the nearer one's now-scrolled-past cell right back out of the
        // accessibility tree, so this order avoids re-finding it a second time.
        XCTAssertTrue(app.revealSidebarLink("algorithmLink.bubblesort").exists)
        XCTAssertTrue(app.revealSidebarLink("algorithmLink.quicksort").exists)
    }
}
