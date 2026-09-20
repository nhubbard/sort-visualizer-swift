import SwiftUI

/// A small, secondary-styled label stacked above its equation — one column, two rows, rather
/// than a label-beside-equation `HStack`/`Grid` row (the earlier `MathView`/`MathGridRow`
/// approach). Used both as one cell of a 2x2 `Grid` (algorithm complexity: best/average over
/// worst/space) and stacked plainly in a `VStack` where there's only one column to begin with
/// (growth-model detected/fitted). Supersedes both `MathView` and `MathGridRow`.
public struct LabeledEquationCell: View {
  private let label: String
  private let equation: String

  public init(label: String, equation: String) {
    self.label = label
    self.equation = equation
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      // A multi-term fitted polynomial can render very wide at a fixed font size -- SwiftMath has
      // no line-wrapping, so a bare `SwiftMathView` here would report that full width as its ideal
      // size and force this cell (and whatever `Grid`/`HStack` contains it) wider to match.
      // `ScrollView(.horizontal)` decouples this cell's layout footprint from the equation's
      // actual rendered width along the scrolling axis; a long equation scrolls instead.
      ScrollView(.horizontal, showsIndicators: false) {
        SwiftMathView(equation: equation, textAlignment: .left)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
