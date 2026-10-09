import XCTest

/// Proves the run-control bar (docked below the visualization via `.safeAreaInset`, replacing the
/// dead global "Playback Speed" Settings slider) is actually reachable and functional: pausing
/// really stops progress, stepping forward while paused doesn't crash, and resuming reaches a
/// correctly-sorted terminal state — the same correctness signal `QuickSortUITests` uses.
@MainActor
final class RunControlBarUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    // Now that portrait is a genuinely supported orientation (not just coerced to landscape by
    // iOS), the simulator's own default boot orientation (portrait) would otherwise leak into
    // this test unpinned — see `ScreenshotUITests`' identical rationale.
    useLandscapeOrientationForUITest()
  }

  func testExpandedRecordingControlIsCenteredWithoutMovingIconButtons() {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let first = app.buttons["runControlResetButton"]
    let transport = app.buttons["runControlPlayPauseButton"]
    let scrubber = app.sliders["runControlScrubSlider"]
    let video = app.buttons["runControlVideoButton"]
    XCTAssertTrue(first.waitForExistence(timeout: 5))
    XCTAssertTrue(transport.exists)
    XCTAssertTrue(scrubber.exists)
    XCTAssertTrue(video.exists)

    let iconPosition = first.frame
    if abs(first.frame.midY - transport.frame.midY) < 12 {
      XCTAssertGreaterThan(first.frame.midX, transport.frame.midX,
        "Utility icons should stay to the right of transport on a wide bar")
    }
    app.activateControlForUITest(video)
    let record = app.buttons["liveRecordingStartButton"]
    XCTAssertTrue(record.waitForExistence(timeout: 5))
    XCTAssertEqual(record.frame.midX, scrubber.frame.midX, accuracy: 12)
    XCTAssertEqual(first.frame.midX, iconPosition.midX, accuracy: 2)
  }

  func testPauseStepAndResumeReachesSortedState() throws {
    let app = XCUIApplication()
    #if targetEnvironment(macCatalyst)
      // Native Catalyst accessibility actions take longer; keep enough tape to pause before
      // the sort finishes, then seek to the end after verifying that playback resumes.
      app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "128", "UI_TEST_PLAYBACK_SPEED": "30"]
    #else
      app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "30"]
    #endif
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")

    let canvas = app.descendants(matching: .any).matching(identifier: "sortVisualizationCanvas")
      .firstMatch
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
    app.activateControlForUITest(playPauseButton)
    Thread.sleep(forTimeInterval: 1.0)
    XCTAssertEqual(playPauseButton.label, "Play", "the transport did not enter its paused state")
    XCTAssertNotEqual(
      statusLabel.value as? String, "sorted",
      "sort reached 'sorted' immediately after pausing — pause isn't actually stopping playback"
    )

    // Stepping forward while paused must not crash and must not resume auto-playback.
    app.activateControlForUITest(app.buttons["runControlStepForwardButton"])
    Thread.sleep(forTimeInterval: 0.5)
    XCTAssertNotEqual(
      statusLabel.value as? String, "sorted",
      "a single manual step forward should not be enough to finish a 24-element sort"
    )

    // Resume and confirm it actually reaches a correctly-sorted terminal state.
    app.activateControlForUITest(playPauseButton)
    XCTAssertEqual(playPauseButton.label, "Pause", "the transport did not resume playback")
    #if targetEnvironment(macCatalyst)
      app.activateControlForUITest(app.buttons["runControlJumpToEndButton"])
    #endif

    // 60s (not 30s): RecordingEngine's primary/secondary auto-retraction (every compare/swap
    // past the first emits 2 extra raw tape entries un-highlighting the previous pair)
    // inflates total tape length, and therefore real playback time at a fixed ops/sec, by
    // roughly 5/3 versus before that fix.
    let terminalState = NSPredicate(format: "value == %@ OR value == %@", "sorted", "sort-failed")
    let reachedTerminalState = XCTNSPredicateExpectation(
      predicate: terminalState, object: statusLabel)
    let result = XCTWaiter().wait(for: [reachedTerminalState], timeout: 60)

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "runcontrolbar-after-pause-step-resume"
    screenshot.lifetime = .keepAlways
    add(screenshot)

    XCTAssertEqual(
      result, .completed, "sort never reached a terminal state after pause/step/resume")
    XCTAssertEqual(
      statusLabel.value as? String, "sorted",
      "sort produced an incorrect result after pause/step/resume")
  }

  /// Covers the transport buttons beyond step-back/step-forward: jump-to-start and jump-to-end
  /// seek across the whole tape (including the shuffle prefix, per `TapeHeader.sortStartIndex`),
  /// and reset returns to the shuffled input specifically — a different, earlier position than
  /// jump-to-end and a different, later position than jump-to-start, since the recorded shuffle
  /// took at least one operation. Each button's own `.disabled` binding (driven live off
  /// `replay.stepIndex`) is the correctness signal: it only turns disabled once a seek has
  /// genuinely landed exactly on that button's target position.
  func testJumpButtonsSeekToExpectedPositions() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")

    let playPauseButton = app.buttons["runControlPlayPauseButton"]
    XCTAssertTrue(playPauseButton.waitForExistence(timeout: 5), "run control bar never appeared")

    let jumpToStartButton = app.buttons["runControlJumpToStartButton"]
    let jumpToEndButton = app.buttons["runControlJumpToEndButton"]
    XCTAssertTrue(jumpToStartButton.exists)
    XCTAssertTrue(jumpToEndButton.exists)

    // Pause immediately so none of these seeks race against auto-playback.
    app.activateControlForUITest(playPauseButton)

    // Jump to end: stepping forward/playing further is no longer possible, but stepping back
    // (and jumping to start) still is, since the tape has earlier positions.
    app.activateControlForUITest(jumpToEndButton)
    XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isEnabled == false"), object: jumpToEndButton
    )], timeout: 5), .completed, "jump-to-end should disable itself once at the last step")
    XCTAssertFalse(
      playPauseButton.isEnabled, "play/pause should disable itself once fully finished")
    XCTAssertTrue(jumpToStartButton.isEnabled)

    // Jump all the way back to true step 0: nothing left to step/jump back further.
    app.activateControlForUITest(jumpToStartButton)
    XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isEnabled == false"), object: jumpToStartButton
    )], timeout: 5), .completed, "jump-to-start should disable itself once at step 0")
    XCTAssertTrue(jumpToEndButton.isEnabled)
    XCTAssertTrue(playPauseButton.isEnabled)
  }

  /// `RunControlBar`'s reset button no longer seeks within the existing tape to the
  /// shuffled-input position — it's `Task { await session.start(size: session.arraySize) }` (see
  /// that button's own `.help` text: "Stop the current sort, shuffle a fresh array at this size,
  /// and sort it again"), a full restart with no `.disabled` binding of its own at all. The
  /// correctness signal is that a genuinely fresh, correctly-sorted run happens afterward, not
  /// any transport button's enabled state.
  func testResetButtonStartsAFreshShuffleAndSort() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "30"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")

    let statusLabel = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "status label never appeared")

    let terminalPredicate = NSPredicate(
      format: "value == %@ OR value == %@", "sorted", "sort-failed")
    let firstTerminal = XCTNSPredicateExpectation(predicate: terminalPredicate, object: statusLabel)
    // 60s, matching `QuickSortUITests`' own budget at a similar size: `RecordingEngine`'s
    // primary/secondary auto-retraction (every compare/swap past the first emits 2 extra raw
    // tape entries un-highlighting the previous pair) inflates real playback time enough that
    // 30s isn't reliably enough at the documented default speed (~30 ops/sec).
    XCTAssertEqual(
      XCTWaiter().wait(for: [firstTerminal], timeout: 60), .completed,
      "the first sort never reached a terminal state"
    )
    XCTAssertEqual(
      statusLabel.value as? String, "sorted", "the first sort produced an incorrect result")

    app.activateControlForUITest(app.buttons["runControlResetButton"])

    // The freshly-shuffled array is vanishingly unlikely to already be sorted at n=24 —
    // leaving "sorted" first is evidence reset genuinely started a new run, not a silent no-op.
    let leftSorted = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value != %@", "sorted"), object: statusLabel
    )
    XCTAssertEqual(
      XCTWaiter().wait(for: [leftSorted], timeout: 10), .completed,
      "resetting should start a fresh shuffle, not silently no-op"
    )

    let secondTerminal = XCTNSPredicateExpectation(
      predicate: terminalPredicate, object: statusLabel)
    XCTAssertEqual(
      XCTWaiter().wait(for: [secondTerminal], timeout: 60), .completed,
      "the freshly-reset sort never reached a terminal state"
    )
    XCTAssertEqual(
      statusLabel.value as? String, "sorted", "the freshly-reset sort produced an incorrect result")
  }

  /// Speed deliberately expands inline (not via `.popover`) — see `RunControlBar`'s own doc
  /// comment; kept this way even now that portrait/multitasking are supported, since inline
  /// expand/collapse never touches `UIPopoverPresentationController` at all.
  func testSpeedButtonExpandsInlineLiveSpeedSlider() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")

    let speedButton = app.buttons["runControlSpeedButton"]
    XCTAssertTrue(speedButton.waitForExistence(timeout: 5))
    app.activateControlForUITest(speedButton)

    let speedSlider = app.sliders["runControlSpeedSlider"]
    XCTAssertTrue(
      speedSlider.waitForExistence(timeout: 5), "speed row never expanded to reveal its slider")
    XCTAssertEqual(speedSlider.label, "Playback speed")
    #if !targetEnvironment(macCatalyst)
    XCTAssertTrue((speedSlider.value as? String)?.contains("operations per second") == true)
    #endif

    app.activateControlForUITest(speedButton)
    XCTAssertFalse(
      speedSlider.waitForExistence(timeout: 2), "tapping again should collapse the speed row")
  }

  func testFixedDurationModeUsesTheLiveDurationSlider() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.openSettingsForUITest()
    let pacingPicker = app.segmentedControls["pacingModePicker"]
    for _ in 0..<5 where !pacingPicker.exists { app.scrollSettingsUpForUITest() }
    XCTAssertTrue(pacingPicker.waitForExistence(timeout: 5))
    app.activateControlForUITest(pacingPicker.buttons["Fixed Duration"])
    app.activateControlForUITest(app.buttons["Done"])

    app.tapSidebarLink("algorithmLink.quicksort")
    let speedButton = app.buttons["runControlSpeedButton"]
    XCTAssertTrue(speedButton.waitForExistence(timeout: 5))
    app.activateControlForUITest(speedButton)
    let durationSlider = app.sliders["runControlDurationSlider"]
    XCTAssertTrue(durationSlider.waitForExistence(timeout: 5))
    XCTAssertEqual(durationSlider.label, "Target duration")
    #if !targetEnvironment(macCatalyst)
    XCTAssertTrue((durationSlider.value as? String)?.contains("seconds") == true)
    #endif
    XCTAssertFalse(app.sliders["runControlSpeedSlider"].exists)
    XCTAssertTrue(app.staticTexts["runControlSpeedValueLabel"].label.contains("target:"))

    // Global pacing persists between UI tests. Put it back after exercising the live row.
    app.openSettingsForUITest()
    for _ in 0..<5 where !pacingPicker.exists { app.scrollSettingsUpForUITest() }
    app.activateControlForUITest(pacingPicker.buttons["Fixed Rate"])
  }

  /// Size deliberately expands inline as a chip row (not a `Stepper`, not a `.popover`) — see
  /// `RunControlBar.sizeRow`'s own doc comment. `runControlSizeButton`'s own accessibility label
  /// is the fixed string "Array Size" (not a live "n=size" value, and true of the old `Stepper`
  /// version too), so this instead confirms the tap took effect via the tapped chip's own
  /// `.isSelected` accessibility trait — driven directly by `session.arraySize`, so it can only
  /// become true once `SortSession.start(size:)` has actually run and rebuilt this row. QuickSort's
  /// `sizeRange` is `16...256` (step 16), so `runControlSizeChip-16` is guaranteed to exist
  /// regardless of the seeded `UI_TEST_ARRAY_SIZE` (24, which isn't itself step-aligned and so may
  /// start with no chip selected at all — expected, not asserted here).
  func testSizeButtonExpandsChipRowAndSelectingAChipUpdatesSize() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")

    let sizeButton = app.buttons["runControlSizeButton"]
    XCTAssertTrue(sizeButton.waitForExistence(timeout: 5))
    app.activateControlForUITest(sizeButton)

    let chipRow = app.scrollViews["runControlSizeChipRow"]
    XCTAssertTrue(chipRow.waitForExistence(timeout: 5), "size row never expanded to reveal its chips")

    let chip = app.buttons["runControlSizeChip-16"]
    XCTAssertTrue(chip.waitForExistence(timeout: 5), "expected a size-16 chip to exist for QuickSort")
    app.activateControlForUITest(chip)

    // `start(size:)` re-records and restarts playback, tearing down and rebuilding this whole
    // row (see `SortView`'s phase-driven `ProgressView` fallback) — so this chip is a fresh
    // element post-tap, re-queried here by its stable identifier rather than a cached reference.
    let selected = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isSelected == true"), object: chip)
    XCTAssertEqual(
      XCTWaiter().wait(for: [selected], timeout: 10), .completed,
      "tapping a size chip should mark it selected once session.arraySize actually changes"
    )

    app.activateControlForUITest(sizeButton)
    XCTAssertFalse(
      chipRow.waitForExistence(timeout: 2), "tapping again should collapse the size chip row")
  }

  #if !targetEnvironment(macCatalyst)
  func testSizeSweepShowsOneBannerAndStopsCurrentPass() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "16", "UI_TEST_PLAYBACK_SPEED": "30",
      "UI_TEST_SHORT_SIZE_SWEEP": "1",
      "UI_TEST_AUTOMATION_ALGORITHMS": "quicksort",
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.quicksort")

    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    let sorted = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "sorted"), object: status)
    XCTAssertEqual(XCTWaiter().wait(for: [sorted], timeout: 10), .completed)

    app.buttons["runControlAutomatorButton"].tap()
    app.buttons.matching(identifier: "automatorMenuItem.sizeSweep").firstMatch.tap()
    let automator = app.buttons["runControlAutomatorButton"]
    let running = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "Size Sweep running"), object: automator)
    XCTAssertEqual(XCTWaiter().wait(for: [running], timeout: 5), .completed)
    let progress = app.staticTexts["automationProgressLabel"]
    XCTAssertTrue(progress.waitForExistence(timeout: 5), "size sweep did not start")
    XCTAssertEqual(app.buttons.matching(identifier: "automationStopButton").count, 1)
    app.buttons["automationStopButton"].tap()
    XCTAssertFalse(progress.waitForExistence(timeout: 5), "size sweep did not stop")
  }
  #endif

  func testLargeReplayJourneyChecksEveryFinalFrame() throws {
    try runLargeReplayJourney(initialSize: 240, nextSize: 256)
  }

  #if !targetEnvironment(macCatalyst)
  func testPortraitReplayJourneyChecksEveryFinalFrame() throws {
    XCUIDevice.shared.orientation = .portrait
    try runLargeReplayJourney(initialSize: 128, nextSize: 144)
  }
  #endif

  private func runLargeReplayJourney(initialSize: Int, nextSize: Int) throws {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": String(initialSize),
      "UI_TEST_PLAYBACK_SPEED": "30",
      "UI_TEST_DETERMINISTIC_REPLAY": "1",
      "UI_TEST_EXPOSE_FRAME": "1",
    ]
    app.launch()
    app.tapSidebarLink("algorithmLink.threesmoothcombsortiterative")

    let canvas = app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch
    let playPause = app.buttons["runControlPlayPauseButton"]
    XCTAssertTrue(canvas.waitForExistence(timeout: 10))
    XCTAssertTrue(playPause.waitForExistence(timeout: 10))
    app.activateControlForUITest(playPause)
    XCTAssertEqual(playPause.label, "Play")

    let paused = try readReplayProbe(canvas)
    XCTAssertEqual(paused.size, initialSize)
    Thread.sleep(forTimeInterval: 0.5)
    XCTAssertEqual(try readReplayProbe(canvas).step, paused.step)

    app.activateControlForUITest(app.buttons["runControlStepForwardButton"])
    XCTAssertEqual(try waitForReplayProbe(canvas, matching: { $0.step == paused.step + 1 }).step, paused.step + 1)
    app.activateControlForUITest(app.buttons["runControlStepBackButton"])
    XCTAssertEqual(try waitForReplayProbe(canvas, matching: { $0.step == paused.step }).step, paused.step)

    app.activateControlForUITest(app.buttons["runControlSpeedButton"])
    let speedSlider = app.sliders["runControlSpeedSlider"]
    XCTAssertTrue(speedSlider.waitForExistence(timeout: 5))
    speedSlider.adjust(toNormalizedSliderPosition: 0.9)
    XCTAssertGreaterThan(try waitForReplayProbe(canvas, matching: { $0.speed > 30 }).speed, 30)
    app.activateControlForUITest(app.buttons["runControlSpeedButton"])

    app.activateControlForUITest(playPause)
    let completed = try waitForReplayProbe(canvas, timeout: 60, matching: { $0.step == $0.total })
    assertFinalFrame(completed, size: initialSize)
    XCTAssertEqual(app.staticTexts["sortStatusLabel"].value as? String, "sorted")

    app.activateControlForUITest(app.buttons["runControlJumpToStartButton"])
    let start = try waitForReplayProbe(canvas, matching: { $0.step == 0 })
    XCTAssertEqual(start.values, Array(1...initialSize))

    app.sliders["runControlScrubSlider"].adjust(toNormalizedSliderPosition: 0.5)
    let middle = try waitForReplayProbe(canvas, matching: { $0.step > 0 && $0.step < $0.total })
    XCTAssertEqual(middle.size, initialSize)
    app.activateControlForUITest(app.buttons["runControlJumpToEndButton"])
    assertFinalFrame(try waitForReplayProbe(canvas, matching: { $0.step == $0.total }), size: initialSize)

    app.activateControlForUITest(app.buttons["runControlSizeButton"])
    let sizeChip = app.buttons["runControlSizeChip-\(nextSize)"]
    XCTAssertTrue(sizeChip.waitForExistence(timeout: 5))
    app.activateControlForUITest(sizeChip)
    _ = try waitForReplayProbe(canvas, timeout: 20, matching: { $0.size == nextSize })
    app.activateControlForUITest(app.buttons["runControlJumpToEndButton"])
    assertFinalFrame(
      try waitForReplayProbe(canvas, matching: { $0.size == nextSize && $0.step == $0.total }),
      size: nextSize)

    app.activateControlForUITest(app.buttons["runControlResetButton"])
    _ = try waitForReplayProbe(canvas, timeout: 20, matching: {
      $0.size == nextSize && $0.step < $0.total
    })
    app.activateControlForUITest(app.buttons["runControlJumpToEndButton"])
    assertFinalFrame(
      try waitForReplayProbe(canvas, matching: { $0.size == nextSize && $0.step == $0.total }),
      size: nextSize)
  }

  private struct ReplayProbe {
    let step: Int
    let total: Int
    let size: Int
    let speed: Int
    let values: [Int]
  }

  private func readReplayProbe(_ canvas: XCUIElement) throws -> ReplayProbe {
    try XCTUnwrap(parseReplayProbe(canvas.value as? String), "Missing replay frame accessibility value")
  }

  private func parseReplayProbe(_ raw: String?) -> ReplayProbe? {
    guard let raw else { return nil }
    let parts = raw.split(separator: "|", omittingEmptySubsequences: false)
    guard parts.count == 5,
      let step = Int(parts[0]), let total = Int(parts[1]),
      let size = Int(parts[2]), let speed = Int(parts[3]) else { return nil }
    let values = parts[4].split(separator: ",").compactMap { Int($0) }
    guard values.count == size else { return nil }
    return ReplayProbe(
      step: step, total: total, size: size, speed: speed, values: values
    )
  }

  private func waitForReplayProbe(
    _ canvas: XCUIElement, timeout: TimeInterval = 10,
    matching matches: (ReplayProbe) -> Bool
  ) throws -> ReplayProbe {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let probe = parseReplayProbe(canvas.value as? String), matches(probe) { return probe }
      Thread.sleep(forTimeInterval: 0.2)
    }
    XCTFail("Replay probe did not reach the expected state")
    return try readReplayProbe(canvas)
  }

  private func assertFinalFrame(_ probe: ReplayProbe, size: Int) {
    XCTAssertEqual(probe.step, probe.total)
    XCTAssertEqual(probe.size, size)
    XCTAssertEqual(probe.values, Array(1...size))
  }
}
