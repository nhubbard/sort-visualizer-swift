import AppIntents

/// The "iterate over available categories" building block — the missing first rung for a fully
/// custom "every size of every algorithm in every category" pipeline: `FindCategoriesIntent` ->
/// Repeat with Each -> `FindAlgorithmsIntent(category:)` -> Repeat with Each ->
/// `FindArraySizesIntent(algorithm:)` -> Repeat with Each -> `RunSortIntent(algorithm:size:)`.
/// Without this, a category could only ever be picked by hand from `FindAlgorithmsIntent`'s own
/// fixed picker — there was no way to *discover* the category list itself as loopable values.
public struct FindCategoriesIntent: AppIntent {
  public static var title: LocalizedStringResource { "Find Categories" }
  public static var description: IntentDescription {
    IntentDescription(
      "Lists Sort Symphony's algorithm categories.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Algorithm Categories", "Sort Categories"],
      resultValueName: "Categories")
  }

  public init() {}

  public func perform() async throws -> some IntentResult & ReturnsValue<[AlgorithmCategoryOption]>
  {
    .result(value: AlgorithmCategoryOption.realCategories)
  }
}
