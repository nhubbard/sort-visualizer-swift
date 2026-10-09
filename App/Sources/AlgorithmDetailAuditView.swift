#if DEBUG
import AlgorithmKit
import Foundation
import SortFeature
import SwiftUI

/// Uses the shipping detail section without recording a sort, so a UI test can capture every
/// algorithm's description, equations, and charts without waiting for impractical algorithms.
struct AlgorithmDetailAuditView: View {
  private let algorithms = AlgorithmRegistry.shared.algorithms.sorted {
    $0.metadata.displayName < $1.metadata.displayName
  }
  private let requestedWidth = ProcessInfo.processInfo.environment["UI_TEST_DETAIL_AUDIT_WIDTH"]
    .flatMap(Double.init)
  private let requestedStart = ProcessInfo.processInfo.environment["UI_TEST_DETAIL_AUDIT_START"]
    .flatMap(Int.init) ?? 0
  private let growthOnly = ProcessInfo.processInfo.environment["UI_TEST_GROWTH_ONLY"] == "1"
  private let compactBigOOnly = ProcessInfo.processInfo.environment["UI_TEST_COMPACT_BIGO_ONLY"] == "1"
  @State private var index = 0

  var body: some View {
    let algorithm = algorithms[index]
    VStack(spacing: 0) {
      HStack {
        Button("Previous") { index = max(0, index - 1) }
          .disabled(index == 0)
          .accessibilityIdentifier("auditPreviousButton")
        Text("\(index + 1) of \(algorithms.count)")
          .accessibilityIdentifier("auditIndexLabel")
        Text(algorithm.id.rawValue)
          .accessibilityIdentifier("auditAlgorithmID")
        Button("Next") { index = min(algorithms.count - 1, index + 1) }
          .disabled(index == algorithms.count - 1)
          .accessibilityIdentifier("auditNextButton")
      }
      .padding(8)

      GeometryReader { geometry in
        let width = min(
          geometry.size.width, requestedWidth.map { CGFloat($0) } ?? geometry.size.width
        )
        ScrollView {
          Group {
            if growthOnly {
              GrowthModelAuditContent(algorithm: algorithm)
                // AlgorithmDetailSection applies this inset around its complexity column.
                // Preserve the shipping chart width inside a narrow detail pane.
                .padding(.all, 32)
            } else if compactBigOOnly {
              CompactBigOAuditContent(algorithm: algorithm)
                .padding(.all, 32)
            } else {
              AlgorithmDetailSection(
                algorithm: algorithm, availableWidth: width, showImplementations: false
              )
            }
          }
            .frame(width: width)
        }
        .id(algorithm.id)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("auditDetailScrollView")
      }
    }
    .onAppear { index = min(max(0, requestedStart), algorithms.count - 1) }
  }
}
#endif
