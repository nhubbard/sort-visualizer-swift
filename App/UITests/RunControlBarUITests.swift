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

        // 60s (not 30s): RecordingEngine's primary/secondary auto-retraction (every compare/swap
        // past the first emits 2 extra raw tape entries un-highlighting the previous pair)
        // inflates total tape length, and therefore real playback time at a fixed ops/sec, by
        // roughly 5/3 versus before that fix.
        let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: terminalState, object: statusLabel)
        let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 60)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "runcontrolbar-after-pause-step-resume"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertEqual(result, .completed, "sort never reached a terminal state after pause/step/resume")
        XCTAssertEqual(statusLabel.value as? String, "sorted",
            "sort produced an incorrect result after pause/step/resume")
    }

    /// Covers the transport buttons beyond step-back/step-forward: jump-to-start and jump-to-end
    /// seek across the whole tape (including the shuffle prefix, per `TapeHeader.sortStartIndex`),
    /// and reset returns to the shuffled input specifically — a different, earlier position than
    /// jump-to-end and a different, later position than jump-to-start, since the recorded shuffle
    /// took at least one operation. Each button's own `.disabled` binding (driven live off
    /// `replay.stepIndex`) is the correctness signal: it only turns disabled once a seek has
    /// genuinely landed exactly on that button's target position.
    func testJumpAndResetButtonsSeekToExpectedPositions() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        app.buttons["algorithmLink.quicksort"].tap()

        let playPauseButton = app.buttons["runControlPlayPauseButton"]
        XCTAssertTrue(playPauseButton.waitForExistence(timeout: 5), "run control bar never appeared")

        let jumpToStartButton = app.buttons["runControlJumpToStartButton"]
        let jumpToEndButton = app.buttons["runControlJumpToEndButton"]
        let resetButton = app.buttons["runControlResetButton"]
        XCTAssertTrue(jumpToStartButton.exists)
        XCTAssertTrue(jumpToEndButton.exists)
        XCTAssertTrue(resetButton.exists)

        // Pause immediately so none of these seeks race against auto-playback.
        playPauseButton.tap()

        // Jump to end: stepping forward/playing further is no longer possible, but stepping back
        // (and resetting, and jumping to start) still is, since the tape has earlier positions.
        jumpToEndButton.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertFalse(jumpToEndButton.isEnabled, "jump-to-end should disable itself once at the last step")
        XCTAssertFalse(playPauseButton.isEnabled, "play/pause should disable itself once fully finished")
        XCTAssertTrue(jumpToStartButton.isEnabled)
        XCTAssertTrue(resetButton.isEnabled,
            "reset should stay enabled at the end — there's a full sort left to replay")

        // Reset to the shuffled input: neither the true start nor the end, so every transport
        // button re-enables except reset itself.
        resetButton.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertFalse(resetButton.isEnabled, "reset should disable itself once exactly at the shuffled-input position")
        XCTAssertTrue(jumpToStartButton.isEnabled,
            "jump-to-start should stay enabled — the shuffle recorded operations before this position")
        XCTAssertTrue(jumpToEndButton.isEnabled)
        XCTAssertTrue(playPauseButton.isEnabled)

        // Jump all the way back to true step 0: nothing left to step/jump back further, but reset
        // is still meaningfully different (the shuffled-input position comes later).
        jumpToStartButton.tap()
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertFalse(jumpToStartButton.isEnabled, "jump-to-start should disable itself once at step 0")
        XCTAssertTrue(resetButton.isEnabled,
            "reset should stay enabled after jump-to-start, since the shuffle moved stepIndex away from sortStartIndex")
        XCTAssertTrue(jumpToEndButton.isEnabled)
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
