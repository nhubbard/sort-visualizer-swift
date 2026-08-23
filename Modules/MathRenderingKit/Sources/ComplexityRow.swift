import AlgorithmKit

/// One renderable row for `LabeledEquationCell` — `label`/`latex` pair, e.g. ("Worst Case", "O(n^2)").
public struct ComplexityRow: Identifiable, Sendable {
  public let id: String
  public let label: String
  public let latex: String
}

extension AlgorithmMetadata {
  /// Derives complexity rows directly from `timeComplexity`/`spaceComplexity` — every
  /// algorithm has this data (it's part of every manifest), unlike the legacy
  /// `complexity.json`-per-bundle approach, which only ~10 of our 20 ported algorithms have.
  /// The plain-ASCII strings authored in Phase 7 ("O(n log n)", "O(n * n!)") are already close
  /// enough to LaTeX for `SwiftMath` to render reasonably; this only escapes the couple of
  /// tokens that need an explicit LaTeX command to look right (`log` as an operator, not three
  /// italic variables; `*` as a proper times sign).
  public var complexityRows: [ComplexityRow] {
    [
      ComplexityRow(id: "best", label: "Best Case", latex: Self.toLatex(timeComplexity.best)),
      ComplexityRow(
        id: "average", label: "Average Complexity", latex: Self.toLatex(timeComplexity.average)),
      ComplexityRow(id: "worst", label: "Worst Case", latex: Self.toLatex(timeComplexity.worst)),
      ComplexityRow(id: "space", label: "Space Complexity", latex: Self.toLatex(spaceComplexity))
    ]
  }

  private static func toLatex(_ complexity: String) -> String {
    complexity
      .replacingOccurrences(of: "log", with: "\\log")
      // Padded with spaces on both sides — LaTeX command names greedily consume any
      // following letters, so an unspaced "*n" would become "\timesn" (parsed as one
      // invalid command instead of "\times" followed by "n"). Extra whitespace around an
      // already-spaced "*" (e.g. "n * n!") is harmless: LaTeX math mode's own spacing rules
      // ignore literal source whitespace.
      .replacingOccurrences(of: "*", with: " \\times ")
  }
}
