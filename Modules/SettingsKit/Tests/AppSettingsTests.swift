import AlgorithmKit
import Foundation
import SortEngineKit
import Testing
import VisualizationKit

@testable import SettingsKit

@MainActor
@Suite
struct AppSettingsTests {
  private func makeIsolatedStore() -> UserDefaults {
    let suiteName = "AppSettingsTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    store.removePersistentDomain(forName: suiteName)
    return store
  }

  @Test
  func defaultsMatchExpectedValuesOnFirstLaunch() {
    let settings = AppSettings(store: makeIsolatedStore())
    #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "bargraph"))
    #expect(settings.playbackSpeed == 30.0)
    #expect(settings.useFixedDurationPacing == false)
    #expect(settings.targetPlaybackDuration == 10.0)
    #expect(settings.compactPlaybackForFixedDuration == false)
    #expect(settings.soundEnabled == false)
    #expect(settings.audioUnitBridgeEnabled == false)
    #expect(settings.synthNoteRange == 36...72)
    #expect(settings.defaultArraySize == 256)
    #expect(settings.codeTheme == CodeThemeID(rawValue: "monokai"))
    #expect(settings.defaultShuffleID == ShuffleID(rawValue: "random"))
    #expect(settings.recordingOperationCap == 300_000)
  }

  @Test
  func mutationsPersistAcrossInstancesSharingTheSameStore() {
    let store = makeIsolatedStore()
    let first = AppSettings(store: store)
    first.selectedVisualizerID = VisualizerID(rawValue: "rainbow")
    first.playbackSpeed = 75.0
    first.useFixedDurationPacing = true
    first.targetPlaybackDuration = 15.0
    first.compactPlaybackForFixedDuration = true
    first.soundEnabled = false
    first.synthNoteRange = 24...96
    first.defaultArraySize = 128
    first.codeTheme = CodeThemeID(rawValue: "dracula")
    first.defaultShuffleID = ShuffleID(rawValue: "shuffledcubic")
    first.recordingOperationCap = 1_000_000

    let second = AppSettings(store: store)
    #expect(second.selectedVisualizerID == VisualizerID(rawValue: "rainbow"))
    #expect(second.playbackSpeed == 75.0)
    #expect(second.useFixedDurationPacing == true)
    #expect(second.targetPlaybackDuration == 15.0)
    #expect(second.compactPlaybackForFixedDuration == true)
    #expect(second.soundEnabled == false)
    #expect(second.synthNoteRange == 24...96)
    #expect(second.defaultArraySize == 128)
    #expect(second.codeTheme == CodeThemeID(rawValue: "dracula"))
    #expect(second.defaultShuffleID == ShuffleID(rawValue: "shuffledcubic"))
    #expect(second.recordingOperationCap == 1_000_000)
  }

  /// Fully synchronous (no `await` between setup and assertions) so this critical section over
  /// the process-wide `VisualizerRegistry.shared` singleton can't interleave with another
  /// `@MainActor`-isolated test's own mutation of it — see `cycleVisualizer()`'s own doc comment
  /// for why it reads that registry directly rather than taking a list as a parameter.
  @Test
  func cycleVisualizerWrapsAroundLikeARingBuffer() {
    let registry = VisualizerRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = ["a", "b", "c"].map(MockVisualizer.init)
    registry.discover()

    let settings = AppSettings(store: makeIsolatedStore())
    settings.selectedVisualizerID = VisualizerID(rawValue: "a")

    settings.cycleVisualizer()
    #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "b"))
    settings.cycleVisualizer()
    #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "c"))
    settings.cycleVisualizer()
    #expect(
      settings.selectedVisualizerID == VisualizerID(rawValue: "a"),
      "should wrap back to the first entry")
  }

  @Test
  func resetToDefaultsRestoresEveryFieldAfterMutation() {
    let settings = AppSettings(store: makeIsolatedStore())
    settings.selectedVisualizerID = VisualizerID(rawValue: "rainbow")
    settings.playbackSpeed = 75.0
    settings.useFixedDurationPacing = true
    settings.targetPlaybackDuration = 15.0
    settings.compactPlaybackForFixedDuration = true
    settings.soundEnabled = true
    settings.audioUnitBridgeEnabled = true
    settings.synthNoteRange = 24...96
    settings.defaultArraySize = 128
    settings.codeTheme = CodeThemeID(rawValue: "dracula")
    settings.defaultShuffleID = ShuffleID(rawValue: "shuffledcubic")
    settings.recordingOperationCap = 1_000_000

    settings.resetToDefaults()

    #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "bargraph"))
    #expect(settings.playbackSpeed == 30.0)
    #expect(settings.useFixedDurationPacing == false)
    #expect(settings.targetPlaybackDuration == 10.0)
    #expect(settings.compactPlaybackForFixedDuration == false)
    #expect(settings.soundEnabled == false)
    #expect(settings.audioUnitBridgeEnabled == false)
    #expect(settings.synthNoteRange == 36...72)
    #expect(settings.defaultArraySize == 256)
    #expect(settings.codeTheme == CodeThemeID(rawValue: "monokai"))
    #expect(settings.defaultShuffleID == ShuffleID(rawValue: "random"))
    #expect(settings.recordingOperationCap == 300_000)
  }

  @Test
  func cycleVisualizerFallsBackToFirstEntryWhenCurrentIDIsUnknown() {
    let registry = VisualizerRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = ["a", "b"].map(MockVisualizer.init)
    registry.discover()

    let settings = AppSettings(store: makeIsolatedStore())
    settings.selectedVisualizerID = VisualizerID(rawValue: "not-in-the-registry")

    settings.cycleVisualizer()
    #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "a"))
  }

  /// Same isolation rationale as `cycleVisualizerWrapsAroundLikeARingBuffer` above, over
  /// `ShuffleRegistry.shared` instead. Deliberately registers the mocks out of alphabetical order
  /// (`c`, `a`, `b`) to actually exercise `cycleShuffle()`'s alphabetical sort, not just registry
  /// order (which would pass even with a bug that dropped the `.sorted` entirely).
  @Test
  func cycleShuffleWrapsAroundLikeARingBufferInAlphabeticalOrder() {
    let registry = ShuffleRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = ["c", "a", "b"].map(MockShuffle.init)
    registry.discover()

    let settings = AppSettings(store: makeIsolatedStore())
    settings.defaultShuffleID = ShuffleID(rawValue: "a")

    settings.cycleShuffle()
    #expect(settings.defaultShuffleID == ShuffleID(rawValue: "b"))
    settings.cycleShuffle()
    #expect(settings.defaultShuffleID == ShuffleID(rawValue: "c"))
    settings.cycleShuffle()
    #expect(
      settings.defaultShuffleID == ShuffleID(rawValue: "a"),
      "should wrap back to the first entry")
  }

  @Test
  func cycleShuffleFallsBackToFirstEntryWhenCurrentIDIsUnknown() {
    let registry = ShuffleRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = ["b", "a"].map(MockShuffle.init)
    registry.discover()

    let settings = AppSettings(store: makeIsolatedStore())
    settings.defaultShuffleID = ShuffleID(rawValue: "not-in-the-registry")

    settings.cycleShuffle()
    #expect(settings.defaultShuffleID == ShuffleID(rawValue: "a"))
  }
}

private struct MockVisualizer: Visualizer {
  let id: VisualizerID
  let metadata = VisualizerMetadata(
    displayName: "Mock", supportsAuxArrays: false, iconName: "circle")

  init(_ rawID: String) {
    id = VisualizerID(rawValue: rawID)
  }

  func draw(_ context: VisualizationContext) -> [DrawCommand] { [] }
}

private struct MockShuffle: ShuffleAlgorithm {
  let id: ShuffleID
  let metadata: ShuffleMetadata

  init(_ rawID: String) {
    id = ShuffleID(rawValue: rawID)
    metadata = ShuffleMetadata(displayName: rawID)
  }

  func record(into engine: inout RecordingEngine) {}
}
