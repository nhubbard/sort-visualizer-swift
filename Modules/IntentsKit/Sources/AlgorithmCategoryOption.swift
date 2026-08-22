import AlgorithmKit
import AppIntents

/// `AlgorithmCategory` can't conform to `AppEnum` directly: App Intents requires an `AppEnum`'s
/// cases to be declared in the same module as the conformance, and `AlgorithmCategory` lives in
/// `AlgorithmKit`. This is a same-cases mirror instead (plus `.all`, a filter sentinel with no
/// `AlgorithmCategory` counterpart), converted back via `algorithmCategory` below.
///
/// `FindAlgorithmsIntent.category` is non-optional with `.all` as its default rather than an
/// `Optional<AlgorithmCategoryOption>` defaulting to `nil`: an unset-default Optional `AppEnum`
/// parameter is exactly the shape that triggers a real, observed App Intents/Shortcuts glitch
/// where the first run after configuring the parameter resolves as unset while every subsequent
/// run resolves correctly. A concrete default removes the unset-vs-nil ambiguity that glitch
/// depends on.
public enum AlgorithmCategoryOption: String, AppEnum {
  case all
  case concurrent, distribution, exchange, hybrid, impractical, insertion
  case merge, miscellaneous, quick, selection

  public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Algorithm Category" }
  public static var caseDisplayRepresentations: [AlgorithmCategoryOption: DisplayRepresentation] {
    [
      .all: "All Categories",
      .concurrent: "Concurrent Sorts",
      .distribution: "Distribution Sorts",
      .exchange: "Exchange Sorts",
      .hybrid: "Hybrid Sorts",
      .impractical: "Impractical Sorts",
      .insertion: "Insertion Sorts",
      .merge: "Merge Sorts",
      .miscellaneous: "Miscellaneous Sorts",
      .quick: "Quick Sorts",
      .selection: "Selection Sorts"
    ]
  }

  /// `nil` only for `.all` (the filter sentinel) — every other case's name and raw value matches
  /// `AlgorithmCategory` exactly.
  public var algorithmCategory: AlgorithmCategory? {
    AlgorithmCategory(rawValue: rawValue)
  }

  /// The 10 real categories, excluding the `.all` filter sentinel — what `FindCategoriesIntent`
  /// returns, and the building block for "for each category, find its algorithms" pipelines.
  public static var realCategories: [AlgorithmCategoryOption] {
    allCases.filter { $0 != .all }
  }
}
