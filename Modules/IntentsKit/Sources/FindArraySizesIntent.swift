import AlgorithmKit
import AppIntents

/// The "iterate over the sizes one algorithm supports" building block — the other missing rung
/// for a fully custom sweep pipeline (see `FindCategoriesIntent`'s doc comment for the whole
/// chain). Returns exactly the same sizes the built-in Size Sweep automation runs through
/// (`Automation.sizes` in `Sort2App.swift`: `sizeRange.steppedValues(by: sizeStep)`), so composing
/// this with `RunSortIntent` reproduces that automation's coverage without needing it at all.
public struct FindArraySizesIntent: AppIntent {
    public static var title: LocalizedStringResource { "Find Array Sizes" }
    public static var description: IntentDescription {
        IntentDescription(
            "Lists every array size one algorithm supports, the same sizes a Size Sweep automation runs through.",
            categoryName: "Sort Symphony",
            searchKeywords: ["Sizes", "Supported Sizes", "Size Sweep"],
            resultValueName: "Array Sizes")
    }

    @Parameter(title: "Algorithm", description: "The algorithm whose supported array sizes to list.")
    public var algorithm: AlgorithmEntity

    public static var parameterSummary: some ParameterSummary {
        Summary("Find array sizes for \(\.$algorithm)")
    }

    public init() {}

    public init(algorithm: AlgorithmEntity) {
        self.algorithm = algorithm
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[Int]> {
        guard let realAlgorithm = AlgorithmRegistry.shared.algorithm(id: algorithm.algorithmID) else {
            throw SortSymphonyIntentError.algorithmUnavailable
        }
        let sizes = realAlgorithm.metadata.sizeRange.steppedValues(by: realAlgorithm.metadata.sizeStep)
        return .result(value: sizes)
    }
}
