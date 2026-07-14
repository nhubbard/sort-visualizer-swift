import AlgorithmKit
import AppIntents

/// The "iterate over available algorithms" building block: pair with Shortcuts' own "Repeat with
/// Each" plus `RunSortIntent` to drive a fully custom demo sequence — the same job Showcase mode's
/// hardcoded, alphabetical, every-algorithm-once loop does today, just composable and
/// user-editable instead of baked into `ContentView`.
public struct FindAlgorithmsIntent: AppIntent {
    public static var title: LocalizedStringResource { "Find Algorithms" }
    public static var description: IntentDescription {
        IntentDescription(
            "Lists Sort Symphony's sorting algorithms, optionally filtered to one category.",
            categoryName: "Sort Symphony")
    }

    @Parameter(title: "Category")
    public var category: AlgorithmCategoryOption?

    public init() {}

    public init(category: AlgorithmCategoryOption?) {
        self.category = category
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[AlgorithmEntity]> {
        let algorithms: [any SortAlgorithm]
        if let category {
            algorithms = AlgorithmRegistry.shared.algorithms(in: category.algorithmCategory)
        } else {
            algorithms = AlgorithmRegistry.shared.algorithms
                .sorted { $0.metadata.displayName < $1.metadata.displayName }
        }
        return .result(value: algorithms.map(AlgorithmEntity.init))
    }
}
