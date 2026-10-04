import AppIntentsTesting
import XCTest

/// Runs through the system's App Intents machinery in a separate process from the app.
/// The production app keeps its iOS 18 deployment target; this test runner requires iOS 27.
@MainActor
final class AppIntentsIntegrationTests: XCTestCase {
  func testFindAlgorithmsIsRegisteredAndReturnsTheBuiltInCatalog() async throws {
    let app = XCUIApplication()
    app.launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let result = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try result.value.as([AnyAppEntity].self)
    XCTAssertEqual(algorithms.count, 196)
    XCTAssertEqual(Set(algorithms.map { $0.identifier.instanceIdentifier }).count, 196)
  }

  func testCategoryParameterFiltersThroughSystemResolution() async throws {
    XCUIApplication().launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let allResult = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let allAlgorithms = try allResult.value.as([AnyAppEntity].self)
    let quickResult = try await definitions.intents["FindAlgorithmsIntent"]
      .makeIntent(category: "quick").run()
    let quickAlgorithms = try quickResult.value.as([AnyAppEntity].self)

    XCTAssertGreaterThan(quickAlgorithms.count, 0)
    XCTAssertLessThan(quickAlgorithms.count, allAlgorithms.count)
    XCTAssertTrue(quickAlgorithms.allSatisfy { allAlgorithms.contains($0) })
  }

  func testSystemFindsRegisteredShuffleVisualizerAndAutomationOptions() async throws {
    XCUIApplication().launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let shuffleResult = try await definitions.intents["FindShufflesIntent"].makeIntent().run()
    let visualizerResult = try await definitions.intents["FindVisualizersIntent"].makeIntent().run()
    let automationResult = try await definitions.intents["FindAutomationsIntent"].makeIntent().run()
    let shuffles = try shuffleResult.value.as([AnyAppEntity].self)
    let visualizers = try visualizerResult.value.as([AnyAppEntity].self)
    let automations = try automationResult.value.as([AnyAppEntity].self)

    XCTAssertEqual(shuffles.count, 43)
    XCTAssertEqual(Set(shuffles.map { $0.identifier.instanceIdentifier }).count, 43)
    XCTAssertFalse(shuffles.contains { $0.identifier.instanceIdentifier == "naive" })
    XCTAssertGreaterThan(visualizers.count, 1)
    XCTAssertEqual(automations.count, 2)
  }

  func testShortcutEntitiesFlowIntoSetAndGetNextActions() async throws {
    XCUIApplication().launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let shuffleResult = try await definitions.intents["FindShufflesIntent"].makeIntent().run()
    let visualizerResult = try await definitions.intents["FindVisualizersIntent"].makeIntent().run()
    let shuffles = try shuffleResult.value.as([AnyAppEntity].self)
    let visualizers = try visualizerResult.value.as([AnyAppEntity].self)
    XCTAssertGreaterThan(shuffles.count, 1)
    XCTAssertGreaterThan(visualizers.count, 1)
    guard shuffles.count > 1, visualizers.count > 1 else { return }

    let setShuffle = definitions.intents["SetShuffleIntent"]
    let setVisualizer = definitions.intents["SetVisualizerIntent"]
    try await setShuffle.makeIntent(shuffle: shuffles[0]).run()
    let nextShuffleResult = try await definitions.intents["GetNextShuffleIntent"].makeIntent().run()
    let nextShuffle = try nextShuffleResult.value.as(AnyAppEntity.self)
    XCTAssertEqual(nextShuffle, shuffles[1])
    try await setShuffle.makeIntent(shuffle: shuffles[0]).run()

    try await setVisualizer.makeIntent(visualizer: visualizers[0]).run()
    let nextVisualizerResult = try await definitions.intents["GetNextVisualizerIntent"]
      .makeIntent().run()
    let nextVisualizer = try nextVisualizerResult.value.as(AnyAppEntity.self)
    XCTAssertEqual(nextVisualizer, visualizers[1])
    try await setVisualizer.makeIntent(visualizer: visualizers[0]).run()
  }

  func testResolvedAlgorithmSuppliesItsReachableSizesThroughTheSystem() async throws {
    XCUIApplication().launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let algorithm = try XCTUnwrap(algorithms.first)

    let sizesResult = try await definitions.intents["FindArraySizesIntent"]
      .makeIntent(algorithm: algorithm).run()
    let maximumResult = try await definitions.intents["FindMaximumArraySizeIntent"]
      .makeIntent(algorithm: algorithm).run()
    let sizes = try sizesResult.value.as([Int].self)
    let maximum = try maximumResult.value.as(Int.self)

    XCTAssertGreaterThan(sizes.count, 1)
    XCTAssertTrue(sizes.allSatisfy { $0 > 0 })
    XCTAssertTrue(zip(sizes, sizes.dropFirst()).allSatisfy { $0 < $1 })
    XCTAssertEqual(sizes.last, maximum)
  }

  func testStopIntentIsRegisteredAndSafeWhenIdle() async throws {
    XCUIApplication().launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    _ = try await definitions.intents["StopIntent"].makeIntent().run()
  }

  func testRunSortThroughSystemCompletesInTheVisibleApp() async throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "8"]
    app.launch()

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"]
      .makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let algorithm = try XCTUnwrap(algorithms.first)
    let availableSizes = try await definitions.intents["FindArraySizesIntent"]
      .makeIntent(algorithm: algorithm).run()
    let size = try XCTUnwrap(try availableSizes.value.as([Int].self).first)

    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 100_000.0).run()
    _ = try await definitions.intents["RunSortIntent"]
      .makeIntent(algorithm: algorithm, size: size).run()

    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 10))
    XCTAssertEqual(status.value as? String, "sorted")
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 30.0).run()
  }

  func testSystemSoundSettingUpdatesTheVisibleSettingsScreen() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")

    _ = try await definitions.intents["SetSoundEnabledIntent"]
      .makeIntent(enabled: false).run()
    app.buttons["settingsButton"].tap()
    let toggle = app.switches["soundEnabledToggle"]
    for _ in 0..<5 where !toggle.exists {
      app.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    XCTAssertEqual(toggle.value as? String, "0")

    _ = try await definitions.intents["SetSoundEnabledIntent"]
      .makeIntent(enabled: true).run()
    let enabled = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "1"), object: toggle)
    XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: 5), .completed)
  }

  func testRunAutomationThroughSystemWaitsForCompletedPasses() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let quickSort = try XCTUnwrap(
      algorithms.first { $0.identifier.instanceIdentifier == "quicksort" })
    let options = try await definitions.intents["FindAutomationsIntent"].makeIntent().run()
    let automations = try options.value.as([AnyAppEntity].self)
    let maxSizeOnly = try XCTUnwrap(
      automations.first { $0.identifier.instanceIdentifier == "maxSizeOnly" })

    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 100_000.0).run()
    _ = try await definitions.intents["RunAutomationIntent"]
      .makeIntent(algorithm: quickSort, automation: maxSizeOnly).run()

    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 10))
    XCTAssertEqual(status.value as? String, "sorted")
    XCTAssertFalse(app.staticTexts["automationProgressLabel"].exists)
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 30.0).run()
  }

  func testSizeSweepThroughSystemCompletesItsShortRange() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let stoogeSort = try XCTUnwrap(
      algorithms.first { $0.identifier.instanceIdentifier == "stoogesort" })
    let options = try await definitions.intents["FindAutomationsIntent"].makeIntent().run()
    let automations = try options.value.as([AnyAppEntity].self)
    let sizeSweep = try XCTUnwrap(
      automations.first { $0.identifier.instanceIdentifier == "sizeSweep" })

    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 100_000.0).run()
    _ = try await definitions.intents["RunAutomationIntent"]
      .makeIntent(algorithm: stoogeSort, automation: sizeSweep).run()

    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 10))
    XCTAssertEqual(status.value as? String, "sorted")
    XCTAssertFalse(app.staticTexts["automationProgressLabel"].exists)
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 30.0).run()
  }

  func testSystemSizeSweepRecordsBothRequestedSizes() async throws {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "32", "UI_TEST_PLAYBACK_SPEED": "1000",
      "UI_TEST_DETERMINISTIC_REPLAY": "1", "UI_TEST_SHORT_SIZE_SWEEP": "1",
      "UI_TEST_AUTOMATION_AUDIT": "1",
    ]
    app.launch()
    app.buttons["algorithmLink.threesmoothcombsortiterative"].tap()
    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "sorted"), object: status
    )], timeout: 20), .completed)
    let probe = app.staticTexts["automationAuditProbe"]
    func audit() -> (count: Int, sizes: String)? {
      guard let raw = probe.value as? String else { return nil }
      let fields = raw.components(separatedBy: "|")
      guard fields.count == 2, let count = Int(fields[0]) else { return nil }
      return (count, fields[1])
    }
    let initialDeadline = Date().addingTimeInterval(20)
    while audit() == nil && Date() < initialDeadline {
      try await Task.sleep(for: .milliseconds(200))
    }
    let before = try XCTUnwrap(audit()).count

    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let algorithm = try XCTUnwrap(
      algorithms.first { $0.identifier.instanceIdentifier == "threesmoothcombsortiterative" })
    let options = try await definitions.intents["FindAutomationsIntent"].makeIntent().run()
    let automations = try options.value.as([AnyAppEntity].self)
    let sizeSweep = try XCTUnwrap(
      automations.first { $0.identifier.instanceIdentifier == "sizeSweep" })
    _ = try await definitions.intents["RunAutomationIntent"]
      .makeIntent(algorithm: algorithm, automation: sizeSweep).run()

    let completedDeadline = Date().addingTimeInterval(20)
    while Date() < completedDeadline {
      if let result = audit(), result.count == before + 2,
        result.sizes.hasPrefix("64,32") { break }
      try await Task.sleep(for: .milliseconds(200))
    }
    let completed = try XCTUnwrap(audit())
    XCTAssertEqual(completed.count, before + 2)
    XCTAssertTrue(completed.sizes.hasPrefix("64,32"), "completed sizes: \(completed.sizes)")
    XCTAssertFalse(app.staticTexts["automationProgressLabel"].exists)
  }

  func testSystemSizeSweepPersistsCapSkipAndContinues() async throws {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_ARRAY_SIZE": "16",
      "UI_TEST_PLAYBACK_SPEED": "1000",
      "UI_TEST_RECORDING_CAP": "5000",
      "UI_TEST_CAP_SWEEP": "1",
      "UI_TEST_CAP_LOG_PROBE": "5000",
      "UI_TEST_DETERMINISTIC_REPLAY": "1",
    ]
    app.launch()
    let algorithmLink = app.buttons["algorithmLink.threesmoothcombsortiterative"]
    XCTAssertTrue(algorithmLink.waitForExistence(timeout: 5))
    algorithmLink.tap()

    let probe = app.staticTexts["capExceededLogProbe"]
    let before = try waitForCapAudit(probe, timeout: 20) { $0.sessionCompletions == 1 }
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let algorithm = try XCTUnwrap(
      algorithms.first { $0.identifier.instanceIdentifier == "threesmoothcombsortiterative" })
    let options = try await definitions.intents["FindAutomationsIntent"].makeIntent().run()
    let automations = try options.value.as([AnyAppEntity].self)
    let sizeSweep = try XCTUnwrap(
      automations.first { $0.identifier.instanceIdentifier == "sizeSweep" })

    _ = try await definitions.intents["RunAutomationIntent"]
      .makeIntent(algorithm: algorithm, automation: sizeSweep).run()

    let after = try waitForCapAudit(app.staticTexts["capExceededLogProbe"], timeout: 15) {
      $0.capCount == before.capCount + 1 && $0.sessionCompletions == 2
    }
    XCTAssertEqual(after.latestSkippedSize, 256)
    XCTAssertEqual(after.completedRecordCount, before.completedRecordCount + 2)
    XCTAssertEqual(app.staticTexts["sortStatusLabel"].value as? String, "sorted")
    XCTAssertFalse(app.staticTexts["automationProgressLabel"].exists)

    app.terminate()
    app.launch()
    XCTAssertTrue(algorithmLink.waitForExistence(timeout: 5))
    algorithmLink.tap()
    let persisted = try waitForCapAudit(app.staticTexts["capExceededLogProbe"], timeout: 15) {
      $0.capCount == after.capCount && $0.latestSkippedSize == 256
    }
    XCTAssertGreaterThanOrEqual(persisted.completedRecordCount, after.completedRecordCount)
  }

  private struct CapAudit {
    let capCount: Int
    let latestSkippedSize: Int
    let completedRecordCount: Int
    let sessionCompletions: Int
  }

  private func parseCapAudit(_ raw: String?) -> CapAudit? {
    guard let raw else { return nil }
    let parts = raw.split(separator: "|")
    guard parts.count == 4,
      let capCount = Int(parts[0]), let size = Int(parts[1]),
      let completed = Int(parts[2]), let revision = Int(parts[3]) else { return nil }
    return CapAudit(
      capCount: capCount, latestSkippedSize: size,
      completedRecordCount: completed, sessionCompletions: revision)
  }

  private func waitForCapAudit(
    _ probe: XCUIElement, timeout: TimeInterval,
    matching matches: (CapAudit) -> Bool
  ) throws -> CapAudit {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let audit = parseCapAudit(probe.value as? String), matches(audit) { return audit }
      Thread.sleep(forTimeInterval: 0.2)
    }
    XCTFail("Cap log probe did not reach the expected persisted state: \(probe.value ?? "missing")")
    return try XCTUnwrap(parseCapAudit(probe.value as? String))
  }

  func testRunSortRejectsUnknownAlgorithmBeforeChangingTheVisibleSession() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    var algorithm = try XCTUnwrap(try catalog.value.as([AnyAppEntity].self).first)
    algorithm.identifier = .init(
      entityType: algorithm.identifier.entityType,
      instanceIdentifier: "not-a-bundled-algorithm")

    do {
      _ = try await definitions.intents["RunSortIntent"]
        .makeIntent(algorithm: algorithm, size: 16).run()
      XCTFail("the system accepted an algorithm that this app cannot resolve")
    } catch {
      XCTAssertFalse(app.staticTexts["sortStatusLabel"].exists)
    }
  }

  func testSetDefaultArraySizeThroughSystemUpdatesTheVisibleSetting() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")

    _ = try await definitions.intents["SetArraySizeIntent"]
      .makeIntent(size: 64).run()
    app.buttons["settingsButton"].tap()
    let stepper = app.steppers["defaultArraySizeStepper"]
    for _ in 0..<5 where !stepper.exists {
      app.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(stepper.waitForExistence(timeout: 5))
    XCTAssertTrue(stepper.label.hasSuffix(": 64"))

    _ = try await definitions.intents["SetArraySizeIntent"]
      .makeIntent(size: 256).run()
  }

  func testCycleArraySizeThroughSystemRejectsIdleState() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")

    do {
      _ = try await definitions.intents["CycleArraySizeIntent"].makeIntent().run()
      XCTFail("cycling array size without a visible sort should report an error")
    } catch {
      XCTAssertFalse(app.staticTexts["sortStatusLabel"].exists)
    }
  }

  func testRepeatedRunSortRequestsClampSizeAndReplaceTheVisibleSession() async throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "8"]
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"]
      .makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let quickSort = try XCTUnwrap(
      algorithms.first { $0.identifier.instanceIdentifier == "quicksort" })
    let sizesResult = try await definitions.intents["FindArraySizesIntent"]
      .makeIntent(algorithm: quickSort).run()
    let sizes = try sizesResult.value.as([Int].self)
    XCTAssertGreaterThan(sizes.count, 1)
    let first = try XCTUnwrap(sizes.first)
    let second = sizes[1]

    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 100_000.0).run()
    _ = try await definitions.intents["RunSortIntent"]
      .makeIntent(algorithm: quickSort, size: 0).run()
    let status = app.staticTexts["sortStatusLabel"]
    XCTAssertTrue(status.waitForExistence(timeout: 10))
    XCTAssertEqual(status.value as? String, "sorted")
    app.buttons["runControlSizeButton"].tap()
    let firstChip = app.buttons["runControlSizeChip-\(first)"]
    XCTAssertTrue(firstChip.waitForExistence(timeout: 5))
    XCTAssertTrue(firstChip.isSelected, "size 0 should clamp to the first reachable size")

    _ = try await definitions.intents["RunSortIntent"]
      .makeIntent(algorithm: quickSort, size: second).run()
    XCTAssertEqual(status.value as? String, "sorted")
    app.buttons["runControlSizeButton"].tap()
    let secondChip = app.buttons["runControlSizeChip-\(second)"]
    XCTAssertTrue(secondChip.waitForExistence(timeout: 5))
    XCTAssertTrue(secondChip.isSelected, "the second request should replace the first session")
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 30.0).run()
  }

  func testSystemPlaybackSpeedActionUpdatesTheOpenReplay() async throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "8"]
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"]
      .makeIntent().run()
    let quickSort = try XCTUnwrap(try catalog.value.as([AnyAppEntity].self).first {
      $0.identifier.instanceIdentifier == "quicksort"
    })
    let sizesResult = try await definitions.intents["FindArraySizesIntent"]
      .makeIntent(algorithm: quickSort).run()
    let size = try XCTUnwrap(try sizesResult.value.as([Int].self).first)

    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 100_000.0).run()
    _ = try await definitions.intents["RunSortIntent"]
      .makeIntent(algorithm: quickSort, size: size).run()
    XCTAssertEqual(app.staticTexts["sortStatusLabel"].value as? String, "sorted")
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 42.0).run()
    app.buttons["runControlSpeedButton"].tap()
    let speed = app.staticTexts["runControlSpeedValueLabel"]
    XCTAssertTrue(speed.waitForExistence(timeout: 5))
    XCTAssertTrue(speed.label.contains("42 ops/sec"))
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 30.0).run()
  }

  func testSystemStopIntentIsAcceptedWhileAutomationIsInFlight() async throws {
    let app = XCUIApplication()
    app.launch()
    let definitions = IntentDefinitions(bundleIdentifier: "com.nhubbard.Sort2.mobile")
    let catalog = try await definitions.intents["FindAlgorithmsIntent"].makeIntent().run()
    let algorithms = try catalog.value.as([AnyAppEntity].self)
    let quickSort = try XCTUnwrap(
      algorithms.first { $0.identifier.instanceIdentifier == "quicksort" })
    let options = try await definitions.intents["FindAutomationsIntent"].makeIntent().run()
    let automations = try options.value.as([AnyAppEntity].self)
    let maxSizeOnly = try XCTUnwrap(
      automations.first { $0.identifier.instanceIdentifier == "maxSizeOnly" })
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 2_000.0).run()
    var automationReturned = false
    let automationRun = Task {
      try await definitions.intents["RunAutomationIntent"]
        .makeIntent(algorithm: quickSort, automation: maxSizeOnly).run()
      automationReturned = true
    }
    // AppIntentsTesting's UI queries can wait for the app to become idle while a sort is
    // animating. Establish an in-flight system request without querying that busy UI.
    try await Task.sleep(for: .seconds(1))
    XCTAssertFalse(automationReturned, "automation finished before Stop was invoked")
    _ = try await definitions.intents["StopIntent"].makeIntent().run()
    _ = try await automationRun.value
    // AppIntentsTesting can queue this second system invocation until the first returns. A
    // wall-clock cutoff therefore cannot establish that Stop cancelled a particular pass;
    // the in-app banner test and SortSession tests assert the actual cancellation behavior.
    XCTAssertFalse(app.staticTexts["automationProgressLabel"].exists,
                   "Stop should clear automation progress after the active pass")
    XCTAssertEqual(app.staticTexts["sortStatusLabel"].value as? String, "sorted")
    _ = try await definitions.intents["SetPlaybackSpeedIntent"]
      .makeIntent(speed: 30.0).run()
  }
}
