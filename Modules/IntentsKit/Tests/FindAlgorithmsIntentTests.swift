import AlgorithmKit
import Foundation
import SettingsKit
import SortEngineKit
import SortFeature
import SwiftUI
import Testing
import VisualizationKit

@testable import IntentsKit

private struct FakeAlgorithm: SortAlgorithm {
  let id: AlgorithmID
  let category: AlgorithmCategory
  var metadata: AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: id.rawValue, category: category, sizeRange: 1...64,
      growthModel: .unconstrained, implementationComplexity: 0, stable: true,
      timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
      spaceComplexity: "O(1)", iconName: "fake")
  }
  func record(into engine: inout RecordingEngine) {}
}

private struct FakeShuffle: ShuffleAlgorithm {
  let id: ShuffleID
  let metadata: ShuffleMetadata
  init(id: String = "intent-test-shuffle", displayName: String = "Intent Test Shuffle") {
    self.id = ShuffleID(rawValue: id)
    metadata = ShuffleMetadata(displayName: displayName)
  }
  func record(into engine: inout RecordingEngine) {}
}

private struct FakeVisualizer: Visualizer {
  let id: VisualizerID
  var metadata: VisualizerMetadata {
    VisualizerMetadata(displayName: id.rawValue, supportsAuxArrays: false, iconName: "square")
  }
  func draw(_ context: VisualizationContext) -> [DrawCommand] { [] }
}

@MainActor
@Suite(.serialized)
struct FindAlgorithmsIntentTests {
  /// This suite serializes its mutations of the process-wide algorithm registry and restores the
  /// original built-ins after each test.
  @Test
  func unavailableIntentErrorsExplainTheRecoveryAction() {
    let messages = [
      SortSymphonyIntentError.algorithmUnavailable,
      .automationUnavailable,
      .noActiveSession,
      .shuffleUnavailable,
      .visualizerUnavailable,
      .requestedShuffleUnavailable,
      .requestedVisualizerUnavailable,
    ].map { String(localized: $0.localizedStringResource) }
    #expect(messages.count == 7)
    #expect(messages.allSatisfy { !$0.isEmpty })
    #expect(messages[2].contains("No sort"))
    #expect(Set(messages).count == messages.count)
  }

  @Test
  func runSortRejectsRemovedOptionalEntitiesBeforeChangingCoordinator() async throws {
    let algorithms = AlgorithmRegistry.shared
    let shuffles = ShuffleRegistry.shared
    let visualizers = VisualizerRegistry.shared
    let restoreAlgorithms = algorithms.builtIns
    let restoreShuffles = shuffles.builtIns
    let restoreVisualizers = visualizers.builtIns
    defer {
      algorithms.builtIns = restoreAlgorithms
      algorithms.discover()
      shuffles.builtIns = restoreShuffles
      shuffles.discover()
      visualizers.builtIns = restoreVisualizers
      visualizers.discover()
    }

    let algorithm = FakeAlgorithm(
      id: AlgorithmID(rawValue: "run-sort-entity-test"), category: .quick)
    let shuffle = FakeShuffle(id: "removed-shuffle")
    let visualizer = FakeVisualizer(id: VisualizerID(rawValue: "removed-visualizer"))
    algorithms.builtIns = [algorithm]
    algorithms.discover()
    shuffles.builtIns = [shuffle]
    shuffles.discover()
    visualizers.builtIns = [visualizer]
    visualizers.discover()
    let algorithmEntity = AlgorithmEntity(algorithm: algorithm)
    let shuffleEntity = ShuffleEntity(shuffle: shuffle)
    let visualizerEntity = VisualizerEntity(visualizer: visualizer)
    let initialToken = SortCoordinator.shared.runToken

    visualizers.builtIns = []
    visualizers.discover()
    do {
      _ = try await RunSortIntent(
        algorithm: algorithmEntity, visualizer: visualizerEntity).perform()
      Issue.record("Run Sort accepted a removed visualizer")
    } catch SortSymphonyIntentError.requestedVisualizerUnavailable {
    }
    #expect(SortCoordinator.shared.runToken == initialToken)

    shuffles.builtIns = []
    shuffles.discover()
    do {
      _ = try await RunSortIntent(
        algorithm: algorithmEntity, shuffle: shuffleEntity).perform()
      Issue.record("Run Sort accepted a removed shuffle")
    } catch SortSymphonyIntentError.requestedShuffleUnavailable {
    }
    #expect(SortCoordinator.shared.runToken == initialToken)
  }

  @Test
  func stopIntentSucceedsWhenThereIsNoActiveSort() async throws {
    #expect(SortCoordinator.shared.activeSortSession == nil)
    _ = try await StopIntent().perform()
    #expect(SortCoordinator.shared.activeSortSession == nil)
  }

  @Test
  func categoryFilterOnlyReturnsThatCategorysAlgorithms() async throws {
    let registry = AlgorithmRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = [
      FakeAlgorithm(id: AlgorithmID(rawValue: "b-quick"), category: .quick),
      FakeAlgorithm(id: AlgorithmID(rawValue: "a-quick"), category: .quick),
      FakeAlgorithm(id: AlgorithmID(rawValue: "some-merge"), category: .merge)
    ]
    registry.discover()

    let filtered = try await FindAlgorithmsIntent(category: .quick).perform()
    let all = try await FindAlgorithmsIntent(category: .all).perform()

    #expect(filtered.value?.map(\.id).sorted() == ["a-quick", "b-quick"])
    #expect(all.value?.count == 3)
    // Alphabetical by displayName (== id here), matching AlgorithmRegistry.algorithms(in:)'s
    // own sidebar-facing sort order.
    #expect(filtered.value?.map(\.id) == ["a-quick", "b-quick"])
  }

  @Test
  func sizeIntentsAgreeOnReachableMaximumAndRejectRemovedAlgorithms() async throws {
    let registry = AlgorithmRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    let algorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "size-test"), category: .quick)
    registry.builtIns = [algorithm]
    registry.discover()
    let entity = AlgorithmEntity(algorithm: algorithm)

    let sizes = try await FindArraySizesIntent(algorithm: entity).perform().value
    let maximum = try await FindMaximumArraySizeIntent(algorithm: entity).perform().value
    let availableSizes = try #require(sizes)
    let maximumSize = try #require(maximum)
    #expect(availableSizes.first == algorithm.metadata.sizeRange.lowerBound)
    #expect(availableSizes.last == maximumSize)
    #expect(availableSizes.count > 1)
    #expect(zip(availableSizes, availableSizes.dropFirst()).allSatisfy { $0.0 < $0.1 })

    registry.builtIns = []
    registry.discover()
    do {
      _ = try await FindArraySizesIntent(algorithm: entity).perform()
      Issue.record("removed algorithm unexpectedly returned array sizes")
    } catch SortSymphonyIntentError.algorithmUnavailable {
    }
    do {
      _ = try await FindMaximumArraySizeIntent(algorithm: entity).perform()
      Issue.record("removed algorithm unexpectedly returned a maximum size")
    } catch SortSymphonyIntentError.algorithmUnavailable {
    }
  }

  @Test
  func playbackAndSoundIntentsUpdateAnAlreadyOpenSort() async throws {
    let settings = AppSettings.shared
    let originalSpeed = settings.playbackSpeed
    let originalSound = settings.soundEnabled
    defer {
      settings.playbackSpeed = originalSpeed
      settings.soundEnabled = originalSound
    }
    let algorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "live-setting-test"), category: .quick)
    let session = SortSession(algorithm: algorithm, shuffle: FakeShuffle(), settings: settings)
    let tape = Tape(
      header: TapeHeader(
        algorithmID: algorithm.id.rawValue, initialValues: [2, 1], visualSeed: 0,
        compareCount: 1, swapCount: 1, recordingDuration: 0,
        recordedAt: Date(timeIntervalSince1970: 0)),
      operations: [.compare(0, 1), .swap(0, 1)])
    settings.playbackSpeed = 1
    session.loadImportedTape(tape)
    let replay = try #require(session.lastReplay)
    replay.pause()
    let coordinator = SortCoordinator.shared
    coordinator.registerActiveSession(session, for: algorithm.id)
    defer { coordinator.unregisterActiveSession(for: algorithm.id) }

    _ = try await SetPlaybackSpeedIntent(speed: 125).perform()
    #expect(settings.playbackSpeed == 125)
    #expect(replay.speed == 125, "the already-open replay must respond to the Shortcut")

    _ = try await SetSoundEnabledIntent(enabled: !originalSound).perform()
    #expect(settings.soundEnabled == !originalSound)
    #expect(session.soundEnabled == !originalSound)
  }

  @Test
  func cycleArraySizeReportsWhenNoSortIsOpen() async throws {
    #expect(SortCoordinator.shared.activeSortSession == nil)
    do {
      _ = try await CycleArraySizeIntent().perform()
      Issue.record("cycling size without an open sort unexpectedly succeeded")
    } catch SortSymphonyIntentError.noActiveSession {
    }
  }

  @Test
  func runSortIntentSelectsAlgorithmAndWaitsForTheRunToFinish() async throws {
    let registry = AlgorithmRegistry.shared
    let restoreBuiltIns = registry.builtIns
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
      coordinator.selectedAlgorithmID = restoreSelection
    }
    let algorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "intent-run-test"), category: .quick)
    registry.builtIns = [algorithm]
    registry.discover()

    var returned = false
    let task = Task {
      _ = try await RunSortIntent(algorithm: AlgorithmEntity(algorithm: algorithm), size: 37)
        .perform()
      returned = true
    }
    for _ in 0..<20 where !coordinator.pendingActionWillAutomate(for: algorithm.id) {
      await Task.yield()
    }
    #expect(coordinator.selectedAlgorithmID == algorithm.id)
    #expect(!returned, "the Shortcut should wait for the animated pass")
    guard case .run(let visualizerID, let size) = coordinator.consumePendingAction(for: algorithm.id)
    else {
      coordinator.resolveCompletion(token: coordinator.runToken)
      task.cancel()
      Issue.record("Run Sort did not queue a run action")
      return
    }
    #expect(visualizerID == nil)
    #expect(size == 37)
    coordinator.resolveCompletion(token: coordinator.runToken)
    _ = try await task.value
    #expect(returned)
  }

  @Test
  func visualizerShowcaseRunsEachStyleInRegistryOrderAndAwaitsCompletion() async throws {
    let algorithmRegistry = AlgorithmRegistry.shared
    let visualizerRegistry = VisualizerRegistry.shared
    let restoreAlgorithms = algorithmRegistry.builtIns
    let restoreVisualizers = visualizerRegistry.builtIns
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    defer {
      algorithmRegistry.builtIns = restoreAlgorithms
      algorithmRegistry.discover()
      visualizerRegistry.builtIns = restoreVisualizers
      visualizerRegistry.discover()
      coordinator.selectedAlgorithmID = restoreSelection
    }
    let algorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "showcase-test"), category: .quick)
    let first = FakeVisualizer(id: VisualizerID(rawValue: "style-z"))
    let second = FakeVisualizer(id: VisualizerID(rawValue: "style-a"))
    algorithmRegistry.builtIns = [algorithm]
    algorithmRegistry.discover()
    visualizerRegistry.builtIns = [first, second]
    visualizerRegistry.discover()
    let expectedSize = algorithm.metadata.effectiveSizeRange(
      operationCap: AppSettings.shared.recordingOperationCap).upperBound

    var returned = false
    let task = Task {
      _ = try await RunVisualizerShowcaseIntent(algorithm: AlgorithmEntity(algorithm: algorithm))
        .perform()
      returned = true
    }
    for style in [first, second] {
      for _ in 0..<20 where !coordinator.pendingActionWillAutomate(for: algorithm.id) {
        await Task.yield()
      }
      guard case .run(let visualizerID, let size) = coordinator.consumePendingAction(for: algorithm.id)
      else {
        coordinator.resolveCompletion(token: coordinator.runToken)
        task.cancel()
        Issue.record("showcase did not queue the next visualizer")
        return
      }
      #expect(visualizerID == style.id)
      #expect(size == expectedSize)
      #expect(!returned, "showcase should wait for every style to finish")
      coordinator.resolveCompletion(token: coordinator.runToken)
    }
    _ = try await task.value
    #expect(returned)
  }

  @Test
  func shortcutListsAndEntityQueriesPreserveOrderAndDropRemovedIDs() async throws {
    let shuffleRegistry = ShuffleRegistry.shared
    let visualizerRegistry = VisualizerRegistry.shared
    let restoreShuffles = shuffleRegistry.builtIns
    let restoreVisualizers = visualizerRegistry.builtIns
    defer {
      shuffleRegistry.builtIns = restoreShuffles
      shuffleRegistry.discover()
      visualizerRegistry.builtIns = restoreVisualizers
      visualizerRegistry.discover()
    }
    let zShuffle = FakeShuffle(id: "shuffle-z", displayName: "Zulu")
    let aShuffle = FakeShuffle(id: "shuffle-a", displayName: "Alpha")
    let zStyle = FakeVisualizer(id: VisualizerID(rawValue: "style-z"))
    let aStyle = FakeVisualizer(id: VisualizerID(rawValue: "style-a"))
    shuffleRegistry.builtIns = [zShuffle, aShuffle]
    shuffleRegistry.discover()
    visualizerRegistry.builtIns = [zStyle, aStyle]
    visualizerRegistry.discover()

    let shuffles = try #require(try await FindShufflesIntent().perform().value)
    let styles = try #require(try await FindVisualizersIntent().perform().value)
    #expect(shuffles.map(\.id) == ["shuffle-a", "shuffle-z"])
    #expect(styles.map(\.id) == ["style-z", "style-a"])

    let resolvedShuffles = await ShuffleEntityQuery().entities(
      for: ["shuffle-z", "removed-shuffle", "shuffle-a"])
    let resolvedStyles = await VisualizerEntityQuery().entities(
      for: ["style-a", "removed-style", "style-z"])
    #expect(resolvedShuffles.map(\.id) == ["shuffle-z", "shuffle-a"])
    #expect(resolvedStyles.map(\.id) == ["style-a", "style-z"])
  }

  @Test
  func runAutomationRejectsRemovedAutomationAndWaitsForItsSweep() async throws {
    let algorithmRegistry = AlgorithmRegistry.shared
    let automationRegistry = AutomationRegistry.shared
    let restoreAlgorithms = algorithmRegistry.builtIns
    let restoreAutomations = automationRegistry.builtIns
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    defer {
      algorithmRegistry.builtIns = restoreAlgorithms
      algorithmRegistry.discover()
      automationRegistry.builtIns = restoreAutomations
      automationRegistry.discover()
      coordinator.selectedAlgorithmID = restoreSelection
    }
    let algorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "automation-test"), category: .quick)
    let automation = Automation(
      id: .sizeSweep, displayName: "Size Sweep", iconName: "repeat", key: "a",
      modifiers: [.command], runsPerSize: 3, sizes: { _ in [1, 2] })
    algorithmRegistry.builtIns = [algorithm]
    algorithmRegistry.discover()
    automationRegistry.builtIns = []
    automationRegistry.discover()
    let algorithmEntity = AlgorithmEntity(algorithm: algorithm)
    let automationEntity = AutomationEntity(automation: automation)

    do {
      _ = try await RunAutomationIntent(
        algorithm: algorithmEntity, automation: automationEntity).perform()
      Issue.record("a removed automation unexpectedly started")
    } catch SortSymphonyIntentError.automationUnavailable {
    }
    #expect(coordinator.selectedAlgorithmID == restoreSelection)

    automationRegistry.builtIns = [automation]
    automationRegistry.discover()
    var returned = false
    let task = Task {
      _ = try await RunAutomationIntent(
        algorithm: algorithmEntity, automation: automationEntity).perform()
      returned = true
    }
    for _ in 0..<100 where !coordinator.pendingActionWillAutomate(for: algorithm.id) {
      await Task.yield()
    }
    #expect(coordinator.selectedAlgorithmID == algorithm.id)
    #expect(!returned, "the Shortcut should wait for the sweep")
    guard case .automation(let queuedID) = coordinator.consumePendingAction(for: algorithm.id)
    else {
      coordinator.resolveCompletion(token: coordinator.runToken)
      task.cancel()
      Issue.record("Run Automation did not queue an automation action")
      return
    }
    #expect(queuedID == automation.id)
    coordinator.resolveCompletion(token: coordinator.runToken)
    _ = try await task.value
    #expect(returned)
  }

  @Test
  func fullSizeSweepQueuesAlgorithmsAlphabeticallyAndAwaitsEachOne() async throws {
    let registry = AlgorithmRegistry.shared
    let restoreBuiltIns = registry.builtIns
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
      coordinator.selectedAlgorithmID = restoreSelection
    }
    let zAlgorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "z-sweep"), category: .quick)
    let aAlgorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "a-sweep"), category: .merge)
    registry.builtIns = [zAlgorithm, aAlgorithm]
    registry.discover()

    var returned = false
    let task = Task {
      _ = try await RunFullSizeSweepIntent().perform()
      returned = true
    }
    for algorithm in [aAlgorithm, zAlgorithm] {
      for _ in 0..<100 where !coordinator.pendingActionWillAutomate(for: algorithm.id) {
        await Task.yield()
      }
      #expect(coordinator.selectedAlgorithmID == algorithm.id)
      #expect(!returned, "the full sweep should wait for each algorithm")
      guard case .automation(let automationID) = coordinator.consumePendingAction(
        for: algorithm.id)
      else {
        coordinator.resolveCompletion(token: coordinator.runToken)
        task.cancel()
        Issue.record("full sweep did not queue the expected algorithm")
        return
      }
      #expect(automationID == .sizeSweep)
      coordinator.resolveCompletion(token: coordinator.runToken)
    }
    _ = try await task.value
    #expect(returned)
  }

  @Test
  func showcaseCyclesStylesAndShufflesBetweenAlphabeticalRuns() async throws {
    let algorithmRegistry = AlgorithmRegistry.shared
    let shuffleRegistry = ShuffleRegistry.shared
    let visualizerRegistry = VisualizerRegistry.shared
    let restoreAlgorithms = algorithmRegistry.builtIns
    let restoreShuffles = shuffleRegistry.builtIns
    let restoreVisualizers = visualizerRegistry.builtIns
    let settings = AppSettings.shared
    let restoreShuffleID = settings.defaultShuffleID
    let restoreVisualizerID = settings.selectedVisualizerID
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    defer {
      algorithmRegistry.builtIns = restoreAlgorithms
      algorithmRegistry.discover()
      shuffleRegistry.builtIns = restoreShuffles
      shuffleRegistry.discover()
      visualizerRegistry.builtIns = restoreVisualizers
      visualizerRegistry.discover()
      settings.defaultShuffleID = restoreShuffleID
      settings.selectedVisualizerID = restoreVisualizerID
      coordinator.selectedAlgorithmID = restoreSelection
    }
    let zAlgorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "z-showcase"), category: .quick)
    let aAlgorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "a-showcase"), category: .merge)
    let firstShuffle = FakeShuffle(id: "showcase-shuffle-a", displayName: "Alpha")
    let secondShuffle = FakeShuffle(id: "showcase-shuffle-z", displayName: "Zulu")
    let firstStyle = FakeVisualizer(id: VisualizerID(rawValue: "showcase-style-a"))
    let secondStyle = FakeVisualizer(id: VisualizerID(rawValue: "showcase-style-z"))
    algorithmRegistry.builtIns = [zAlgorithm, aAlgorithm]
    algorithmRegistry.discover()
    shuffleRegistry.builtIns = [secondShuffle, firstShuffle]
    shuffleRegistry.discover()
    visualizerRegistry.builtIns = [firstStyle, secondStyle]
    visualizerRegistry.discover()
    settings.defaultShuffleID = firstShuffle.id
    settings.selectedVisualizerID = firstStyle.id

    var returned = false
    let task = Task {
      _ = try await RunShowcaseIntent().perform()
      returned = true
    }
    for (algorithm, shuffleID, styleID) in [
      (aAlgorithm, secondShuffle.id, secondStyle.id),
      (zAlgorithm, firstShuffle.id, firstStyle.id)
    ] {
      for _ in 0..<100 where !coordinator.pendingActionWillAutomate(for: algorithm.id) {
        await Task.yield()
      }
      #expect(coordinator.selectedAlgorithmID == algorithm.id)
      #expect(settings.defaultShuffleID == shuffleID)
      #expect(settings.selectedVisualizerID == styleID)
      #expect(!returned, "showcase should wait for each pass")
      guard case .run(let visualizerOverride, let size) = coordinator.consumePendingAction(
        for: algorithm.id)
      else {
        coordinator.resolveCompletion(token: coordinator.runToken)
        task.cancel()
        Issue.record("showcase did not queue the expected algorithm")
        return
      }
      #expect(visualizerOverride == nil)
      #expect(size == algorithm.metadata.effectiveSizeRange(
        operationCap: settings.recordingOperationCap).upperBound)
      coordinator.resolveCompletion(token: coordinator.runToken)
    }
    _ = try await task.value
    #expect(returned)
  }

  @Test
  func categoryListExcludesTheAllCategoriesFilter() async throws {
    let categories = try #require(try await FindCategoriesIntent().perform().value)
    #expect(categories == AlgorithmCategoryOption.realCategories)
    #expect(categories.count == AlgorithmCategory.allCases.count)
    #expect(!categories.contains(.all))
  }

  @Test
  func shortcutCatalogAndAutomationQueryExposeTheRegisteredChoices() async throws {
    #expect(SortSymphonyShortcuts.appShortcuts.count == 6)
    let registry = AutomationRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    let sizeSweep = Automation(
      id: .sizeSweep, displayName: "Size Sweep", iconName: "repeat", key: "a",
      modifiers: [.command], runsPerSize: 3, sizes: { _ in [1, 2] })
    let maxSize = Automation(
      id: .maxSizeOnly, displayName: "Max Size Only", iconName: "arrow.up", key: "m",
      modifiers: [.command], runsPerSize: 1, sizes: { _ in [64] })
    registry.builtIns = [sizeSweep, maxSize]
    registry.discover()

    let found = try #require(try await FindAutomationsIntent().perform().value)
    #expect(found.map(\.id) == ["sizeSweep", "maxSizeOnly"])
    let query = AutomationEntityQuery()
    let resolved = await query.entities(for: ["maxSizeOnly", "removed", "sizeSweep"])
    #expect(resolved.map(\.id) == ["maxSizeOnly", "sizeSweep"])
    let suggested = await query.suggestedEntities()
    #expect(suggested.map(\.id) == found.map(\.id))
  }

  @Test
  func settingIntentsCycleAndReportEmptyRegistries() async throws {
    let shuffleRegistry = ShuffleRegistry.shared
    let visualizerRegistry = VisualizerRegistry.shared
    let restoreShuffles = shuffleRegistry.builtIns
    let restoreVisualizers = visualizerRegistry.builtIns
    let settings = AppSettings.shared
    let restoreShuffleID = settings.defaultShuffleID
    let restoreVisualizerID = settings.selectedVisualizerID
    let restoreSize = settings.defaultArraySize
    defer {
      shuffleRegistry.builtIns = restoreShuffles
      shuffleRegistry.discover()
      visualizerRegistry.builtIns = restoreVisualizers
      visualizerRegistry.discover()
      settings.defaultShuffleID = restoreShuffleID
      settings.selectedVisualizerID = restoreVisualizerID
      settings.defaultArraySize = restoreSize
    }
    let firstShuffle = FakeShuffle(id: "setting-shuffle-a", displayName: "Alpha")
    let secondShuffle = FakeShuffle(id: "setting-shuffle-z", displayName: "Zulu")
    let firstStyle = FakeVisualizer(id: VisualizerID(rawValue: "setting-style-a"))
    let secondStyle = FakeVisualizer(id: VisualizerID(rawValue: "setting-style-z"))
    shuffleRegistry.builtIns = [secondShuffle, firstShuffle]
    shuffleRegistry.discover()
    visualizerRegistry.builtIns = [firstStyle, secondStyle]
    visualizerRegistry.discover()

    _ = try await SetShuffleIntent(shuffle: ShuffleEntity(shuffle: firstShuffle)).perform()
    _ = try await SetVisualizerIntent(visualizer: VisualizerEntity(visualizer: firstStyle)).perform()
    _ = try await SetArraySizeIntent(size: 37).perform()
    #expect(settings.defaultShuffleID == firstShuffle.id)
    #expect(settings.selectedVisualizerID == firstStyle.id)
    #expect(settings.defaultArraySize == 37)

    let nextShuffle = try #require(try await GetNextShuffleIntent().perform().value)
    #expect(nextShuffle.id == secondShuffle.id.rawValue)
    _ = try await CycleVisualizerIntent().perform()
    #expect(settings.selectedVisualizerID == secondStyle.id)
    let wrappedStyle = try #require(try await GetNextVisualizerIntent().perform().value)
    #expect(wrappedStyle.id == firstStyle.id.rawValue)
    _ = try await StopIntent().perform()

    shuffleRegistry.builtIns = []
    shuffleRegistry.discover()
    visualizerRegistry.builtIns = []
    visualizerRegistry.discover()
    do {
      _ = try await GetNextShuffleIntent().perform()
      Issue.record("Get Next Shuffle unexpectedly returned from an empty registry")
    } catch SortSymphonyIntentError.shuffleUnavailable {
    }
    do {
      _ = try await GetNextVisualizerIntent().perform()
      Issue.record("Get Next Visualizer unexpectedly returned from an empty registry")
    } catch SortSymphonyIntentError.visualizerUnavailable {
    }
  }

  @Test
  func runSortRoutesOverridesAndRejectsAnUnavailableAlgorithm() async throws {
    let registry = AlgorithmRegistry.shared
    let shuffleRegistry = ShuffleRegistry.shared
    let visualizerRegistry = VisualizerRegistry.shared
    let restoreBuiltIns = registry.builtIns
    let restoreShuffles = shuffleRegistry.builtIns
    let restoreVisualizers = visualizerRegistry.builtIns
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
      shuffleRegistry.builtIns = restoreShuffles
      shuffleRegistry.discover()
      visualizerRegistry.builtIns = restoreVisualizers
      visualizerRegistry.discover()
      coordinator.selectedAlgorithmID = restoreSelection
    }
    let algorithm = FakeAlgorithm(id: AlgorithmID(rawValue: "override-sort"), category: .quick)
    let shuffle = FakeShuffle(id: "override-shuffle")
    let style = FakeVisualizer(id: VisualizerID(rawValue: "override-style"))
    shuffleRegistry.builtIns = [shuffle]
    shuffleRegistry.discover()
    visualizerRegistry.builtIns = [style]
    visualizerRegistry.discover()
    let intent = RunSortIntent(
      algorithm: AlgorithmEntity(algorithm: algorithm),
      visualizer: VisualizerEntity(visualizer: style), shuffle: ShuffleEntity(shuffle: shuffle),
      size: 23)
    registry.builtIns = []
    registry.discover()
    do {
      _ = try await intent.perform()
      Issue.record("Run Sort unexpectedly accepted a removed algorithm")
    } catch SortSymphonyIntentError.algorithmUnavailable {
    }

    registry.builtIns = [algorithm]
    registry.discover()
    let task = Task { _ = try await intent.perform() }
    for _ in 0..<100 where !coordinator.pendingActionWillAutomate(for: algorithm.id) {
      await Task.yield()
    }
    #expect(coordinator.pendingShuffleOverride(for: algorithm.id) == shuffle.id)
    guard case .run(let visualizerID, let size) = coordinator.consumePendingAction(for: algorithm.id)
    else {
      coordinator.resolveCompletion(token: coordinator.runToken)
      task.cancel()
      Issue.record("Run Sort did not queue its overrides")
      return
    }
    #expect(visualizerID == style.id)
    #expect(size == 23)
    #expect(coordinator.pendingShuffleOverride(for: algorithm.id) == nil)
    coordinator.resolveCompletion(token: coordinator.runToken)
    _ = try await task.value
  }
}
