import SwiftUI

/// One label+equation row inside a `Grid` — supersedes the old standalone `MathView` (an `HStack`
/// pairing a label with a `SwiftMathView`), which put label and equation in independent per-row
/// `HStack`s with nothing keeping their column widths aligned across rows, and no way for a Grid
/// to size the equation column tightly. Every call site (algorithm complexity, growth-model
/// comparison) now wraps a `Grid { ForEach(...) { MathGridRow(...) } }` instead, so labels and
/// equations line up in two real columns, sized from actual content rather than each row's own
/// independent `HStack` guess.
public struct MathGridRow: View {
  private let text: String
  private let equation: String

  public init(text: String, equation: String) {
    self.text = text
    self.equation = equation
  }

  /// Relies on the enclosing `Grid` being created with `alignment: .leading` (both columns want
  /// it, so there's no need for a per-cell `.gridColumnAlignment` override here).
  public var body: some View {
    GridRow {
      Text("\(text):")
        .font(.system(size: 16, weight: .bold, design: .default))
        // Without this, a long label (e.g. "Fitted (Used by App):") wraps to two lines the
        // moment the Grid's total ideal width doesn't fit the available space, rather than the
        // label column simply growing to fit it on one line -- `fixedSize` reports this Text's
        // true single-line width as non-negotiable, so Grid sizes the column to that instead.
        .fixedSize(horizontal: true, vertical: false)
      SwiftMathView(equation: equation, textAlignment: .left)
    }
  }
}
