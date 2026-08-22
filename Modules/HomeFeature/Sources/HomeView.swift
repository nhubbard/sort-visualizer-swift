import DesignSystemKit
import MarkdownUI
import SwiftUI

/// Originally ported verbatim from `Legacy/Shared/Views/Main/HomeView.swift`'s `home_copy` string;
/// its categorization paragraph has since been rewritten to describe this app's actual ten
/// `AlgorithmCategory` families instead of the legacy Logarithmic/Quadratic/Weird complexity split,
/// which never matched this codebase's sidebar. Inlined here rather than round-tripped through a
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

    This app organizes its algorithms into ten families, grouped by how they work rather than how \
    fast they run: **Concurrent**, **Distribution**, **Exchange**, **Hybrid**, **Impractical**, \
    **Insertion**, **Merge**, **Miscellaneous**, **Quick**, and **Selection** sorts. A family shares \
    a common strategy: selection sorts repeatedly find the smallest remaining element, for \
    instance, while merge sorts split the data apart and merge it back together in order.

    Complexity still varies within every family. **Quick Sort**, for example, is typically \
    efficient, with a time complexity of O(*n* log *n*). **Bubble Sort**, on the other hand, is \
    quadratic, with a time complexity of O(*n*²). The **Impractical** family is reserved for \
    algorithms that are correct but absurd -- sorts that work by brute force, accident, or joke, \
    and are difficult to compare to anything else.

    Space and time complexity can also be further subdivided into 3 different cases: best case, \
    average case, and worst case.

    Sorting algorithms can be difficult to understand, and it's easy to get confused. This app aims to \
    help you understand sorting algorithms by showing their actions in real time. Without further ado, \
    let's get started -- choose an algorithm from the sidebar on the left!
    """
}
