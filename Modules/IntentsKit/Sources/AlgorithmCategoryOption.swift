import AlgorithmKit
import AppIntents

/// `AlgorithmCategory` itself can't conform to `AppEnum` from here: App Intents' compile-time
/// metadata extraction requires an `AppEnum`'s cases to be declared in the same module as the
/// conformance ("enums implemented in an imported framework or library are not supported"), and
/// `AlgorithmCategory` lives in `AlgorithmKit`. This is a same-cases mirror instead, converted back
/// to the real type via `algorithmCategory` below — used only as `FindAlgorithmsIntent`'s optional
/// filter parameter.
public enum AlgorithmCategoryOption: String, AppEnum {
    case concurrent, distribution, exchange, hybrid, impractical, insertion
    case merge, miscellaneous, quick, selection

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Algorithm Category" }
    public static var caseDisplayRepresentations: [AlgorithmCategoryOption: DisplayRepresentation] {
        [
            .concurrent: "Concurrent Sorts",
            .distribution: "Distribution Sorts",
            .exchange: "Exchange Sorts",
            .hybrid: "Hybrid Sorts",
            .impractical: "Impractical Sorts",
            .insertion: "Insertion Sorts",
            .merge: "Merge Sorts",
            .miscellaneous: "Miscellaneous Sorts",
            .quick: "Quick Sorts",
            .selection: "Selection Sorts",
        ]
    }

    /// Case names and raw values match `AlgorithmCategory` exactly, so this never actually falls
    /// back to `.miscellaneous` — the fallback only exists to satisfy `RawRepresentable`'s
    /// failable initializer.
    public var algorithmCategory: AlgorithmCategory {
        AlgorithmCategory(rawValue: rawValue) ?? .miscellaneous
    }
}
