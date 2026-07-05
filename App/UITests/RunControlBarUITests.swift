import XCTest

/// Proves the run-control bar (docked below the visualization via `.safeAreaInset`, replacing the
/// dead global "Playback Speed" Settings slider) is actually reachable and functional: pausing
/// really stops progress, stepping forward while paused doesn't crash, and resuming reaches a
/// correctly-sorted terminal state — the same correctness signal `QuickSortUITests` uses.
final class RunControlBarUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPauseStepAndResumeReachesSortedState() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        app.buttons["algorithmLink.quicksort"].tap()

        let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), "visualization canvas never appeared")

        let statusLabel = app.staticTexts["sortStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared")

        let playPauseButton = app.buttons["runControlPlayPauseButton"]
        XCTAssertTrue(playPauseButton.waitForExistence(timeout: 5), "run control bar never appeared")
        XCTAssertTrue(app.buttons["runControlStepBackButton"].exists)
        XCTAssertTrue(app.buttons["runControlStepForwardButton"].exists)
        XCTAssertTrue(app.buttons["runControlSoundToggle"].exists)
        XCTAssertTrue(app.buttons["runControlSpeedButton"].exists)
        XCTAssertTrue(app.sliders["runControlScrubSlider"].exists)

        // Pause almost immediately, then confirm it's genuinely stopped rather than racing to
        // finish anyway — the whole point of this bar existing is that this button does something.
        playPauseButton.tap()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertNotEqual(
            statusLabel.value as? String, "sorted",
            "sort reached 'sorted' immediately after pausing — pause isn't actually stopping playback"
        )

        // Stepping forward while paused must not crash and must not resume auto-playback.
        app.buttons["runControlStepForwardButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertNotEqual(
            statusLabel.value as? String, "sorted",
            "a single manual step forward should not be enough to finish a 24-element sort"
        )

        // Resume and confirm it actually reaches a correctly-sorted terminal state.
        playPauseButton.tap()

        let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: terminalState, object: statusLabel)
        let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 30)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "runcontrolbar-after-pause-step-resume"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertEqual(result, .completed, "sort never reached a terminal state after pause/step/resume")
        XCTAssertEqual(statusLabel.value as? String, "sorted", "sort produced an incorrect result after pause/step/resume")
    }

    /// Speed deliberately expands inline (not via `.popover`) — a `.popover`'s
    /// `UIPopoverPresentationController` demands to support every interface orientation, which
    /// has no overlap with this app's deliberately landscape-only orientation support, producing
    /// "Supported orientations has no common orientation with the application" and unreliable
    /// popover behavior.
    func testSpeedButtonExpandsInlineLiveSpeedSlider() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        app.buttons["algorithmLink.quicksort"].tap()

        let speedButton = app.buttons["runControlSpeedButton"]
        XCTAssertTrue(speedButton.waitForExistence(timeout: 5))
        speedButton.tap()

        let speedSlider = app.sliders["runControlSpeedSlider"]
        XCTAssertTrue(speedSlider.waitForExistence(timeout: 5), "speed row never expanded to reveal its slider")

        speedButton.tap()
        XCTAssertFalse(speedSlider.waitForExistence(timeout: 2), "tapping again should collapse the speed row")
    }
}
