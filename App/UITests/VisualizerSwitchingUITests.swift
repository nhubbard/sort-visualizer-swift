import XCTest

/// Phase 5's checkpoint: switching the visualizer picker mid-sort changes the rendering live, with
/// zero disruption to the running `SortSession`/`ReplayEngine` — proof the algorithm and
/// visualization plugin axes are genuinely orthogonal. Settings is presented as a sheet rather than
/// a navigation push specifically so the underlying sort screen's state survives the round trip.
@MainActor
final class VisualizerSwitchingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        // Now that portrait is a genuinely supported orientation (not just coerced to landscape by
        // iOS), the simulator's own default boot orientation (portrait) would otherwise leak into
        // this test unpinned — see `ScreenshotUITests`' identical rationale.
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func testSwitchingVisualizerMidSortDoesNotDisruptTheRunningSession() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        app.tapSidebarLink("algorithmLink.quicksort")

        let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), "canvas never appeared")

        let statusLabel = app.staticTexts["sortStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared")

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "settings button never appeared")
        settingsButton.tap()

        // `.pickerStyle(.menu)` only exposes its options as accessibility elements once its menu
        // is actually open — tapping the picker itself first (by its own identifier) is required
        // before "Rainbow" (or any other option) exists anywhere in the tree to find.
        app.buttons["visualizerPicker"].tap()

        let rainbowOption = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Rainbow"))
            .firstMatch
        XCTAssertTrue(rainbowOption.waitForExistence(timeout: 5), "visualizer picker option \"Rainbow\" never appeared")
        rainbowOption.tap()

        app.buttons["Done"].tap()

        // Same session, not a fresh one — the canvas and status label must still be the ones
        // driven by the SortSession that was already running before the detour through Settings.
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), "canvas disappeared after switching visualizers mid-sort")

        // 60s (not 30s): RecordingEngine's primary/secondary auto-retraction (every compare/swap
        // past the first emits 2 extra raw tape entries un-highlighting the previous pair)
        // inflates total tape length, and therefore real playback time at a fixed ops/sec, by
        // roughly 5/3 versus before that fix.
        let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: terminalState, object: statusLabel)
        let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 60)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "rainbow-after-switch-final-state"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertEqual(result, .completed, "sort never reached a terminal state after switching visualizers mid-run")
        XCTAssertEqual(
            statusLabel.value as? String, "sorted",
            "sort produced an incorrect result after switching visualizers mid-run"
        )
    }
}
