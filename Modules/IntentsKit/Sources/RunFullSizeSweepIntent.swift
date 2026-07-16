import AlgorithmKit
import AppIntents
import SortFeature

/// The bulk-data-generation loop (⌘⇧A's Size Sweep) run across *every* algorithm instead of just
/// one — every size each algorithm supports, three runs per size, alphabetically. This is the
/// heaviest pre-built Shortcut by far (potentially hours for the full algorithm list); Shortcuts'
/// own progress UI and Stop control are the only way to check on or cancel it mid-run, same as
/// `RunAutomationIntent` for a single algorithm.
public struct RunFullSizeSweepIntent: AppIntent {
    public static var title: LocalizedStringResource { "Run Full Size Sweep" }
    public static var description: IntentDescription {
        IntentDescription(
            "Runs a size sweep (every supported size, three times each) for every algorithm, in alphabetical order.",
            categoryName: "Sort Symphony",
            searchKeywords: ["Full Sweep", "All Algorithms", "Size Sweep"])
    }

    public static var openAppWhenRun: Bool { true }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        let algorithms = AlgorithmRegistry.shared.algorithms
            .sorted { $0.metadata.displayName < $1.metadata.displayName }
        for algorithm in algorithms {
            await SortCoordinator.shared.runAutomation(algorithm: algorithm, automationID: .sizeSweep)
        }
        return .result()
    }
}
