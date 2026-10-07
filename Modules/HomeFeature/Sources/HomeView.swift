import DesignSystemKit
import MarkdownUI
import SwiftUI

private final class HomeLocalizationBundle {}

/// The Home introduction is Markdown in this module's string catalog. Its category paragraph
/// describes the app's ten `AlgorithmCategory` families rather than the old legacy complexity
/// split, which never matched this codebase's sidebar.
public struct HomeView: View {
  private let onTryQuickSort: () -> Void

  public init(onTryQuickSort: @escaping () -> Void) {
    self.onTryQuickSort = onTryQuickSort
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 2) {
        Text("Welcome to").bold()
        RandomizingHeader(text: "SORT SYMPHONY")
        Button("Try Quick Sort", action: onTryQuickSort)
          .buttonStyle(.bordered)
          .accessibilityIdentifier("homeTryQuickSortButton")
          .accessibilityHint("Opens a Quick Sort example from the algorithm catalog")
          .padding(.top, 12)
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

  private static var welcomeCopy: String {
    String(localized: "home.welcomeCopy", bundle: Bundle(for: HomeLocalizationBundle.self))
  }
}
