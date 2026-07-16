import AlgorithmKit
import AppIntents
import SortFeature

/// Opens Sort Symphony, selects `algorithm` exactly the way a sidebar tap would, and awaits one
/// fully-animated pass before returning — the same "await genuine completion" contract Showcase
/// mode's per-algorithm step already relies on (`SortSession.runSinglePass(size:)`), just reachable
/// from a Shortcut instead of only from `ContentView`'s own hardcoded loop. Chaining this with
/// `FindAlgorithmsIntent` and Shortcuts' "Repeat with Each" reproduces Showcase entirely inside the
/// Shortcuts app.
public struct RunSortIntent: AppIntent {
    public static var title: LocalizedStringResource { "Run Sort" }
    public static var description: IntentDescription {
        IntentDescription(
            "Runs one sorting algorithm in Sort Symphony and waits for the full animated pass to finish.",
            categoryName: "Sort Symphony",
            searchKeywords: ["Sort", "Run Algorithm", "Play Sort"])
    }

    public static var openAppWhenRun: Bool { true }

    @Parameter(title: "Algorithm", description: "The algorithm to run, selected exactly as if tapped in the sidebar.")
    public var algorithm: AlgorithmEntity
    @Parameter(title: "Visualizer", description: "Defaults to whichever visualizer is already selected.")
    public var visualizer: VisualizerEntity?
    @Parameter(title: "Shuffle", description: "Defaults to the app's configured default shuffle.")
    public var shuffle: ShuffleEntity?
    @Parameter(title: "Array Size", description: "Defaults to the app's configured default size, clamped to the algorithm's own range.")
    public var size: Int?

    public static var parameterSummary: some ParameterSummary {
        Summary("Run \(\.$algorithm)") {
            \.$visualizer
            \.$shuffle
            \.$size
        }
    }

    public init() {}

    public init(algorithm: AlgorithmEntity, visualizer: VisualizerEntity? = nil, shuffle: ShuffleEntity? = nil, size: Int? = nil) {
        self.algorithm = algorithm
        self.visualizer = visualizer
        self.shuffle = shuffle
        self.size = size
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        guard let realAlgorithm = AlgorithmRegistry.shared.algorithm(id: algorithm.algorithmID) else {
            throw SortSymphonyIntentError.algorithmUnavailable
        }
        await SortCoordinator.shared.runSort(
            algorithm: realAlgorithm,
            visualizerID: visualizer?.visualizerID,
            shuffleID: shuffle?.shuffleID,
            size: size
        )
        return .result()
    }
}
