import DesignSystemKit
import MarkdownUI
import SwiftUI

/// Ported from `Legacy/Shared/Views/Main/HomeView.swift` — the welcome copy is the same text
/// (`Localizable.strings`' `home_copy`), inlined here rather than round-tripped through a
/// `String(localized:)` lookup key, since this module owns no localization catalog of its own yet.
public struct HomeView: View {
  public init() {}

  public var body: some View {
    ScrollView {
      VStack(spacing: 2) {
        Text("Welcome to").bold()
        RandomizingHeader(text: "SORT SYMPHONY")
        Markdown(Self.welcomeCopy)
          .markdownTextStyle {
            FontFamilyVariant(.normal)
            FontFamily(.system())
            FontSize(.em(1))
          }
          .lineSpacing(1.75)
          .padding()
      }
    }
    .padding()
    .navigationTitle("Home")
  }

  private static let welcomeCopy = """
    Sorting algorithms are used to sort a data structure according to a specific order relationship, \
    such as numerical order or lexicographical order.

    This operation is one of the most important and widespread in computer science. For a long time, \
    new methods have been developed to make this procedure faster and faster.

    There are hundreds of different sorting algorithms available, each with their own characteristics. \
    They are classified according to two metrics: space complexity and time complexity.

    Those two kinds of complexity are represented with asymptotic notations, mainly with the symbols O, \
    \u{398}, and \u{3A9}, which represent the upper bound, the tight bound, and the lower bound of an \
    algorithm's complexity. The numeric value of these bounds is specified in parentheses in terms of \
    the number *n*, which is the number of elements in the data structure.

    Most sorting algorithms fall into two specific categories:

    * **Logarithmic**: The complexity is proportional to the binary logarithm of *n* (i.e. log₂(*n*)). \
    An example of a logarithmic sorting algorithm is **Quick Sort**, which has space and time \
    complexity of O(*n* log *n*).
    * **Quadratic**: The complexity is proportional to the square of *n*. An example of a quadratic \
    sorting algorithm is **Bubble Sort**, with a time complexity of O(*n*²).

    There is also a third category: **Weird** algorithms. These don't follow a Logarithmic or \
    Quadratic complexity, and are a bit more difficult to compare.

    Space and time complexity can also be further subdivided into 3 different cases: best case, \
    average case, and worst case.

    Sorting algorithms can be difficult to understand, and it's easy to get confused. This app aims to \
    help you understand sorting algorithms by showing their actions in real time. Without further ado, \
    let's get started -- choose an algorithm from the sidebar on the left!
    """
}
