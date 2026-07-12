import XCTest

/// The global default speed feeds every *new* session's starting `ReplayEngine.speed`
/// (`SortSession.startReplay`) — proven end-to-end here by changing it in Settings, then opening a
/// fresh sort and reading the run-control bar's own speed readout, rather than only checking
/// `AppSettings` in isolation (`AppSettingsTests` already covers that). Restores the slider back to
/// the documented default (30/sec) before finishing: `GnomeSortUITests`' 90s timeout budget and
/// `RunControlBarUITests`' "still mid-sort a beat after pausing" assumption both depend on this
/// value staying near its real default, and `UserDefaults.standard` persists across test runs
/// within the same simulator.
final class DefaultPlaybackSpeedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testChangingDefaultPlaybackSpeedSeedsANewlyOpenedSort() throws {
        let app = XCUIApplication()
        app.launch()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // A drag gesture at normalized 1.0 lands very close to, but not always exactly on, the
        // slider's maximum — so this reads back the caption's actual number rather than asserting
        // an exact "200 operations/second" match.
        let speedSlider = app.sliders["playbackSpeedSlider"]
        scrollUntilVisible(speedSlider, in: app)
        speedSlider.adjust(toNormalizedSliderPosition: 1.0) // slider's maximum: 200/sec
        let raisedSpeed = try XCTUnwrap(operationsPerSecond(fromCaptionIn: app),
            "no '<n> operations/second' caption found after raising the slider")
        XCTAssertGreaterThan(raisedSpeed, 150,
            "dragging to the slider's maximum should land near 200, not close to the old default")
        app.buttons["Done"].tap()

        app.tapSidebarLink("algorithmLink.quicksort")
        let speedButton = app.buttons["runControlSpeedButton"]
        XCTAssertTrue(speedButton.waitForExistence(timeout: 5))
        speedButton.tap() // expands the inline speed row

        let speedValueLabel = app.staticTexts["runControlSpeedValueLabel"]
        XCTAssertTrue(speedValueLabel.waitForExistence(timeout: 5))
        let sessionSpeed = try XCTUnwrap(speedValueLabel.label.split(separator: " ").compactMap { Int($0) }.first)
        XCTAssertEqual(
            sessionSpeed, Int(raisedSpeed),
            "a freshly opened sort should start at the new default speed, not the old one"
        )

        // Restore the documented default so other UI tests' timing assumptions keep holding.
        settingsButton.tap()
        scrollUntilVisible(speedSlider, in: app)
        speedSlider.adjust(toNormalizedSliderPosition: (30.0 - 1.0) / (200.0 - 1.0))
        let restoredSpeed = try XCTUnwrap(operationsPerSecond(fromCaptionIn: app),
            "no '<n> operations/second' caption found after restoring the slider")
        XCTAssertTrue((20...40).contains(restoredSpeed),
            "restoring the slider toward its documented default landed too far from 30/sec: \(restoredSpeed)")
        app.buttons["Done"].tap()
    }

    private func operationsPerSecond(fromCaptionIn app: XCUIApplication) -> Int? {
        let caption = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "operations/second")).firstMatch
        guard caption.waitForExistence(timeout: 5) else { return nil }
        return Int(caption.label.split(separator: " ").first ?? "")
    }

    /// The Settings `Form` doesn't put off-screen rows in the accessibility tree until scrolled
    /// into view, and the speed section sits below Visualizer/Shuffle's full picker lists — swipe
    /// incrementally rather than one fixed-distance swipe, which can overshoot past the section
    /// entirely. Each fresh sheet presentation resets scroll position, so both call sites need this.
    private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 where !element.exists {
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) never scrolled into view")
    }
}
