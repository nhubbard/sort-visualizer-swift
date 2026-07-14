import XCTest

/// Portrait is now a genuinely declared, supported orientation (see `Project.swift`'s
/// `UISupportedInterfaceOrientations` — `UIRequiresFullScreen` is gone since Apple has announced
/// it'll stop being honored). Every other functional UI test pins `.landscapeLeft` explicitly
/// (`ScreenshotUITests`' rationale) to keep validating the primary orientation unchanged; this is
/// the one test that deliberately runs in `.portrait` instead, to prove the narrower width doesn't
/// break navigation, `RunControlBar`, or `AlgorithmDetailSection`.
@MainActor
final class PortraitOrientationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testSortingAlgorithmIsFullyUsableInPortrait() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
        app.launch()

        // Same navigation path every other functional UI test uses — if `NavigationSplitView`
        // collapses to one column at this width, this call (and the sidebar link it looks for)
        // failing here is exactly the empirical signal `SidebarNavigation.swift`'s helpers would
        // need a reveal-the-sidebar step added for.
        app.tapSidebarLink("algorithmLink.quicksort")

        let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), "visualization canvas never appeared in portrait")

        let statusLabel = app.staticTexts["sortStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared in portrait")

        // RunControlBar's transportRow/statsCaption both fall back to a stacked ViewThatFits
        // candidate under narrow width — confirms the fallback still surfaces every control
        // (not just that *something* renders) rather than silently clipping them.
        let playPauseButton = app.buttons["runControlPlayPauseButton"]
        XCTAssertTrue(playPauseButton.waitForExistence(timeout: 5), "play/pause button not reachable in portrait")
        let automatorButton = app.buttons["runControlAutomatorButton"]
        XCTAssertTrue(automatorButton.exists, "automator menu button not reachable in portrait")

        let terminalPredicate = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
        let reachedTerminal = XCTNSPredicateExpectation(predicate: terminalPredicate, object: statusLabel)
        XCTAssertEqual(
            XCTWaiter().wait(for: [reachedTerminal], timeout: 60), .completed,
            "sort never reached a terminal state in portrait — replay likely hung")
        XCTAssertEqual(statusLabel.value as? String, "sorted", "sort completed but produced an incorrect result in portrait")

        // AlgorithmDetailSection stacks Description above Complexity below its width threshold —
        // confirms the stacked layout still renders (not just the wide one), reachable by scrolling.
        let descriptionHeading = app.staticTexts["Description"]
        for _ in 0..<10 where !descriptionHeading.exists {
            app.swipeUp()
        }
        XCTAssertTrue(descriptionHeading.exists, "AlgorithmDetailSection's Description heading never became reachable in portrait")
    }
}
