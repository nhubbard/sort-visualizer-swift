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
        Text(String(localized: "Welcome to", bundle: Self.localizationBundle)).bold()
        RandomizingHeader(text: "SORT SYMPHONY")
        Button(action: onTryQuickSort) {
          Text(String(localized: "Try Quick Sort", bundle: Self.localizationBundle))
        }
          .buttonStyle(.bordered)
          .accessibilityIdentifier("homeTryQuickSortButton")
          .accessibilityHint(String(localized: "Opens a Quick Sort example from the algorithm catalog", bundle: Self.localizationBundle))
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
    .navigationTitle(String(localized: "Home", bundle: Self.localizationBundle))
  }

  private static var localizationBundle: Bundle {
    Bundle(for: HomeLocalizationBundle.self)
  }

  private static var welcomeCopy: String {
    String(localized: "home.welcomeCopy", bundle: localizationBundle)
  }
}
