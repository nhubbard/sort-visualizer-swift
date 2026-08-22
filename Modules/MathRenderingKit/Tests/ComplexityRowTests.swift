import AlgorithmKit
import Testing

@testable import MathRenderingKit

private func makeMetadata(best: String, average: String, worst: String, space: String)
  -> AlgorithmMetadata {
  AlgorithmMetadata(
    displayName: "Fake",
    category: .exchange,
    sizeRange: 1...1,
    growthModel: .unconstrained,
    stable: true,
    timeComplexity: ComplexityBounds(best: best, average: average, worst: worst),
    spaceComplexity: space,
    iconName: "fake"
  )
}

@Suite
struct ComplexityRowTests {
  /// Regression test: MSD Radix Sort's `"O(d*n)"` rendered as the LaTeX error "Invalid command
  /// \timesn" — `*` was replaced with `"\times"` with no surrounding space, so a `*` directly
  /// followed by a letter (no space, unlike e.g. "n * n!") produced one run-on token LaTeX reads
  /// as a single invalid command instead of "\times" followed by "n".
  @Test
  func timesIsPaddedWithSpacesSoItNeverMergesIntoTheFollowingLetter() {
    let metadata = makeMetadata(best: "O(d*n)", average: "O(d*n)", worst: "O(d*n)", space: "O(1)")
    for row in metadata.complexityRows where row.id != "space" {
      #expect(!row.latex.contains("\\timesn"), "\(row.id): \(row.latex)")
      #expect(row.latex.contains(" \\times "), "\(row.id): \(row.latex)")
    }
  }

  /// `*` already surrounded by spaces (e.g. Bogo/Bozo Sort's `"O(n * n!)"`) must still render
  /// correctly — extra whitespace around `\times` is harmless in LaTeX math mode.
  @Test
  func alreadySpacedTimesStillRendersCorrectly() {
    let metadata = makeMetadata(
      best: "O(n)", average: "O(n * n!)", worst: "O(n * n!)", space: "O(1)")
    let average = metadata.complexityRows.first { $0.id == "average" }!
    #expect(average.latex == "O(n  \\times  n!)")
  }

  @Test
  func logBecomesALatexCommand() {
    let metadata = makeMetadata(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)", space: "O(n)")
    let best = metadata.complexityRows.first { $0.id == "best" }!
    #expect(best.latex == "O(n \\log n)")
  }

  @Test
  func complexityRowsHasExactlyFourRowsInBestAverageWorstSpaceOrder() {
    let metadata = makeMetadata(best: "O(1)", average: "O(n)", worst: "O(n^2)", space: "O(1)")
    let rows = metadata.complexityRows
    #expect(rows.map(\.id) == ["best", "average", "worst", "space"])
    #expect(
      rows.map(\.label) == [
        "Best Case", "Average Complexity", "Worst Case", "Space Complexity"
      ])
  }

  @Test
  func complexityWithNeitherLogNorStarPassesThroughUnchanged() {
    let metadata = makeMetadata(best: "O(1)", average: "O(1)", worst: "O(1)", space: "O(1)")
    #expect(metadata.complexityRows.allSatisfy { $0.latex == "O(1)" })
  }
}
