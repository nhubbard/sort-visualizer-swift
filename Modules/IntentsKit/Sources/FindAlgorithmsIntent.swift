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
            categoryName: "Sort Symphony",
            searchKeywords: ["Sorting Algorithms", "List Algorithms", "All Algorithms"],
            resultValueName: "Algorithms")
    }

    // Non-optional with `.all` as the default — see `AlgorithmCategoryOption`'s own doc comment
    // for why an `Optional<AlgorithmCategoryOption>` defaulting to `nil` is the wrong shape here.
    @Parameter(title: "Category", description: "Filters to one category, or leave as All Categories to list every algorithm.", default: .all)
    public var category: AlgorithmCategoryOption

    public static var parameterSummary: some ParameterSummary {
        Summary("Find algorithms in \(\.$category)")
    }

    public init() {
        category = .all
    }

    public init(category: AlgorithmCategoryOption) {
        self.category = category
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[AlgorithmEntity]> {
        let algorithms: [any SortAlgorithm]
        if let realCategory = category.algorithmCategory {
            algorithms = AlgorithmRegistry.shared.algorithms(in: realCategory)
        } else {
            algorithms = AlgorithmRegistry.shared.algorithms
                .sorted { $0.metadata.displayName < $1.metadata.displayName }
        }
        return .result(value: algorithms.map(AlgorithmEntity.init))
    }
}
