import AlgorithmKit
import AudioEngineKit
import Observation
import SettingsKit
import SortFeature

/// Orchestrates ArrayV's "Showcase" mode: run every registered algorithm once, each at its own
/// `sizeRange.upperBound`, advancing automatically. Reuses `SortSession.runShowcasePass()` (built
/// on the same tested completion-detection machinery `runAutomation(_:)` uses) rather than
/// reimplementing "wait for one real, fully-animated run to finish" itself.
@Observable
@MainActor
public final class ShowcaseController {
    public private(set) var currentIndex = 0
    public private(set) var currentSession: SortSession?
    public private(set) var isRunning = false
    private var task: Task<Void, Never>?

    /// Same sort order as the sidebar (`ContentView`'s `AlgorithmRegistry.shared.algorithms(in:)`
    /// sorts by `displayName` too) — alphabetical, not registration order.
    public var algorithms: [any SortAlgorithm] {
        AlgorithmRegistry.shared.algorithms.sorted { $0.metadata.displayName < $1.metadata.displayName }
    }

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        let algorithms = self.algorithms
        let shuffleID = AppSettings.shared.defaultShuffleID
        guard let shuffle = ShuffleRegistry.shared.shuffle(id: shuffleID) else {
            isRunning = false
            return
        }
        task = Task {
            for (index, algorithm) in algorithms.enumerated() {
                guard !Task.isCancelled else { break }
                currentIndex = index
                let session = SortSession(algorithm: algorithm, shuffle: shuffle, audio: AudioService.shared)
                currentSession = session
                await session.runShowcasePass()
            }
            isRunning = false
            currentSession = nil
        }
    }

    public func stop() {
        task?.cancel()
        isRunning = false
        currentSession = nil
    }
}
