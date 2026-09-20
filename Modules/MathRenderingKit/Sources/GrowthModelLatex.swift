import AlgorithmKit

/// LaTeX for `DetectedGrowthModel`/`OperationGrowthModel`, alongside `ComplexityRow.swift`'s own
/// `AlgorithmMetadata` LaTeX. Every string below is built directly from numeric coefficients via
/// string interpolation -- never by running a second find/replace escaping pass over text that
/// might already contain a LaTeX command (that's exactly what broke `ComplexityRow.toLatex` when
/// `timeComplexity` briefly had hand-baked `\log`/`\times` in it: its own `"log" -> "\\log"`
/// replacement matched the `log` inside the already-present `\log`, producing a literal double
/// backslash, which SwiftMath reads as a line break, not backslash-followed-by-command). Each
/// command's backslash is written exactly once here, at the one place it's introduced.
extension AlgorithmMetadata {
  /// The real detected growth family's own formula, e.g. `"1.2n^{1.8}"` for a `powerLaw` fit --
  /// nil when this algorithm hasn't been through `apply_detected_models.py` yet.
  public var detectedGrowthModelLatex: String? {
    detectedGrowthModel?.latex
  }

  /// The Taylor-polynomial approximation the app actually uses for sizing (`growthModel`),
  /// expanded as a LaTeX polynomial in `(n - anchorSize)`.
  public var fittedGrowthModelLatex: String {
    growthModel.latex
  }
}

extension DetectedGrowthModel {
  public var latex: String {
    switch family {
    case .powerLaw:
      return "\(formattedCoefficient(coefficients[0]))n^{\(formattedCoefficient(coefficients[1]))}"
    case .powerLog:
      return
        "\(formattedCoefficient(coefficients[0]))n^{\(formattedCoefficient(coefficients[1]))} \\log n"
    case .polynomialIntercept:
      // `coefficients` is `[a, b, c]` for `a*n^2 + b*n + c` -- descending power, the opposite of
      // `polynomialLatex`'s ascending-power convention (matching `OperationGrowthModel`'s own
      // `coefficients[i]` == coefficient of `x^i`) -- so reverse before handing it off.
      return polynomialLatex(coefficients: Array(coefficients.reversed()), variableLatex: "n")
    case .exponential:
      // Two bare numeric literals side by side (`a`, `b^n`) would be ambiguous without an
      // explicit operator, unlike a coefficient directly against a lettered variable below.
      return
        "\(formattedCoefficient(coefficients[0])) \\times \(formattedCoefficient(coefficients[1]))^{n}"
    case .nToTheNLike:
      return
        "\(formattedCoefficient(coefficients[0]))e^{\(formattedCoefficient(coefficients[1]))n \\log n}"
    case .factorial:
      return
        "\(formattedCoefficient(coefficients[0]))e^{\(formattedCoefficient(coefficients[1]))"
        + "(n \\log n - n)}"
    }
  }
}

extension OperationGrowthModel {
  public var latex: String {
    polynomialLatex(coefficients: coefficients, variableLatex: shiftedVariableLatex(anchor: anchorSize))
  }
}

private func formattedCoefficient(_ value: Double) -> String {
  // `.grouping(.never)` matters here, not just cosmetically -- the default locale-aware grouping
  // separator (e.g. "238,710") would land directly in a LaTeX string, where a bare comma is a
  // syntactically meaningful list separator, not a thousands mark.
  value.formatted(.number.precision(.significantDigits(1...6)).grouping(.never))
}

/// `(n - anchor)`, `(n + |anchor|)` if `anchor` is somehow negative, or bare `n` when `anchor`
/// is exactly 0 -- the base `polynomialLatex` raises to each term's power.
private func shiftedVariableLatex(anchor: Double) -> String {
  guard anchor != 0 else { return "n" }
  let sign = anchor < 0 ? "+" : "-"
  return "(n \(sign) \(formattedCoefficient(abs(anchor))))"
}

/// Renders `Σ coefficients[i] * variableLatex^i` as a LaTeX sum, dropping zero-coefficient terms
/// entirely and formatting the leading term without a redundant `"+"`. Shared between
/// `polynomialIntercept`-family detected models and every `OperationGrowthModel`, since both are
/// literally a sum of `coefficient * variable^power` terms -- just a different `variableLatex`
/// (`"n"` vs. a shifted `"(n - anchor)"`).
private func polynomialLatex(coefficients: [Double], variableLatex: String) -> String {
  var terms: [String] = []
  for (power, coefficient) in coefficients.enumerated() where coefficient != 0 {
    let magnitude = formattedCoefficient(abs(coefficient))
    let variablePart: String
    switch power {
    case 0: variablePart = ""
    case 1: variablePart = variableLatex
    default: variablePart = "\(variableLatex)^{\(power)}"
    }
    let term = variablePart.isEmpty ? magnitude : "\(magnitude)\(variablePart)"
    let sign = coefficient < 0 ? "- " : (terms.isEmpty ? "" : "+ ")
    terms.append(sign + term)
  }
  return terms.isEmpty ? "0" : terms.joined(separator: " ")
}
