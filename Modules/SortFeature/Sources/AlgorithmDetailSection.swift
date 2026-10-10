import Foundation
import AlgorithmKit
import DesignSystemKit
import MarkdownUI
import MathRenderingKit
import SettingsKit
import SwiftUI
import TipKit
import UIKit

/// The `AlgorithmDetailSection(entry:)` Documentation/docs/architecture/features.md describes as sitting below the
/// live sort — description + complexity (rendered via `LabeledEquationCell`, derived from
/// `AlgorithmMetadata` directly so every algorithm has it, not just the ones with legacy
/// content) + a language-picker code sample, when `AlgorithmDetailContent` has any.
public struct AlgorithmDetailSection: View {
  private let algorithm: any SortAlgorithm
  @State private var content: AlgorithmDetailContent?
  @State private var contentLoading = true
  @State private var contentUnavailable = false
  /// `ScrollingSortView.body`'s own top-level `GeometryReader` (otherwise only used to size
  /// `SortView`'s frame) passed straight through — not `ViewThatFits`: `descriptionColumn`/
  /// `complexityColumn` below both use `.frame(maxWidth: .infinity)`, which happily shrinks to
  /// any width, so `ViewThatFits` would never actually detect an overflow to fall back from.
  private let availableWidth: CGFloat
  private let analyticsRevision: Int
  private let showImplementations: Bool
  private let showDescription: Bool
  @Environment(AppSettings.self) private var settings
  @State private var selectedLanguage: CodeLanguage = .all[0]
  /// Highlighting a sample re-parses its full source and re-styles every attribute run — cheap
  /// once, but `AttributedCodeView(selected.source, theme:)` used to pay that cost again on every
  /// SwiftUI body evaluation of this view, not just on an actual language switch, causing a
  /// visible hitch on the newly-ported, hundreds-of-lines algorithms. Computed once per
  /// `content`/theme change in `highlightAllSamples`, off the main actor, instead.
  @State private var highlighted: [CodeLanguage: AttributedString] = [:]
  @State private var plainSamples: [CodeLanguage: String] = [:]
  #if DEBUG
  @State private var appliedThemeID: CodeThemeID?
  #endif

  /// Below this, `descriptionColumn`/`complexityColumn` stack instead of sitting side by side —
  /// comfortably under a landscape detail pane's width, comfortably over a narrow portrait one's.
  private static let stackedLayoutThreshold: CGFloat = 700

  public init(
    algorithm: any SortAlgorithm, availableWidth: CGFloat, analyticsRevision: Int = 0,
    showImplementations: Bool = true, showDescription: Bool = true
  ) {
    self.algorithm = algorithm
    self.availableWidth = availableWidth
    self.analyticsRevision = analyticsRevision
    self.showImplementations = showImplementations
    self.showDescription = showDescription
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      #if DEBUG
        if ProcessInfo.processInfo.environment["UI_TEST_ACTIVE_SETTINGS_AUDIT"] == "1" {
          Text("Code theme applied probe")
            .font(.caption2)
            .accessibilityIdentifier("codeThemeAppliedProbe")
            .accessibilityValue("\(appliedThemeID?.rawValue ?? "loading")|\(highlighted.count)")
        }
      #endif
      if contentUnavailable {
        ContentUnavailableView(
          String(localized: "Reference content unavailable", bundle: .module), systemImage: "doc.questionmark",
          description: Text(String(localized: "The bundled algorithm details could not be loaded. Reinstall the app to restore descriptions and code examples.", bundle: .module))
        )
        .accessibilityIdentifier("algorithmDetailsLoadError")
      }
      if availableWidth < Self.stackedLayoutThreshold {
        VStack(alignment: .leading, spacing: 24) {
          if showDescription { descriptionColumn }
          complexityColumn
        }
      } else {
        HStack(alignment: .top, spacing: 16) {
          if showDescription { descriptionColumn }
          complexityColumn
        }
      }

      if showImplementations && !contentUnavailable {
        VStack(alignment: .leading, spacing: 8) {
          Text(String(localized: "Implementations", bundle: .module)).font(.title2.bold())
          if contentLoading {
            ProgressView(String(localized: "Loading code examples…", bundle: .module))
          } else if let content, !content.codeSamples.isEmpty {
            TipView(CodeDiscoveryTip())
              .accessibilityIdentifier("sortCodeTip")
            Picker(String(localized: "Language", bundle: .module), selection: $selectedLanguage) {
              ForEach(content.codeSamples, id: \.language) { sample in
                Text(sample.language.title).tag(sample.language)
              }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("codeLanguagePicker")
            .onChange(of: selectedLanguage) {
              CodeDiscoveryTip.hasExploredCode = true
              CodeDiscoveryTip().invalidate(reason: .actionPerformed)
            }

            if let plain = plainSamples[selectedLanguage] {
              Button {
                UIPasteboard.general.string = plain
                CodeDiscoveryTip.hasExploredCode = true
                CodeDiscoveryTip().invalidate(reason: .actionPerformed)
              } label: {
                Label(String(localized: "Copy Code", bundle: .module), systemImage: "doc.on.doc")
              }
              .accessibilityIdentifier("copyAlgorithmCode")
              .frame(maxWidth: .infinity)
            }

            if content.codeSamples.contains(where: { $0.language == selectedLanguage }) {
              // AttributedCodeView sizes to its own intrinsic width (`.fixedSize`), so
              // left inside this leading-aligned VStack it hugs the left edge instead of
              // sitting under the wider Description/Complexity content above it.
              HStack {
                Spacer(minLength: 0)
                if let styled = highlighted[selectedLanguage] {
                  AttributedCodeView(
                    attributed: styled, backgroundColor: settings.codeTheme.makeTheme().getBgColor()
                  )
                  .accessibilityIdentifier("algorithmCodeSample")
                } else {
                  ProgressView()
                    .frame(minWidth: 200, minHeight: 100)
                }
                Spacer(minLength: 0)
              }
            }
            if let plain = plainSamples[selectedLanguage] {
              Text(String(localized: "\(selectedLanguage.title) implementation, \(codeLineCount(plain)) lines.", bundle: .module))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("algorithmCodeSummary")
            }
          } else {
            Text(String(localized: "No code samples available yet.", bundle: .module)).foregroundStyle(.secondary)
          }
        }
      }
    }
    .padding(.all, 32)
    .task(id: algorithm.id) {
      content = nil
      contentLoading = true
      contentUnavailable = false
      highlighted = [:]
      plainSamples = [:]
      #if DEBUG
        appliedThemeID = nil
      #endif
      switch await AlgorithmDetailStore.shared.loadState(for: algorithm.id.rawValue) {
      case .loaded(let loaded): content = loaded
      case .unavailable: contentUnavailable = true
      }
      contentLoading = false
      if let firstLanguage = content?.codeSamples.first?.language {
        selectedLanguage = firstLanguage
      }
      if showImplementations, let content {
        await highlightAllSamples(content)
      }
    }
    .onChange(of: settings.codeTheme) {
      if showImplementations, let content {
        Task { await highlightAllSamples(content) }
      }
    }
  }

  private func codeLineCount(_ source: String) -> Int {
    source.split(separator: "\n", omittingEmptySubsequences: false).count
      - (source.hasSuffix("\n") ? 1 : 0)
  }

  private func highlightAllSamples(_ content: AlgorithmDetailContent) async {
    // `themeID`, not a resolved `theme`, so `CodeHighlighter.highlight(_:themeID:)` can skip
    // recomputation entirely for a source/theme pair it's already highlighted — full sweep
    // remounts this view (and re-triggers this exact `.task`) on every combo, not just every
    // algorithm change, so without this cache the same unchanged source got re-highlighted
    // roughly once a second for the entire sweep.
    let themeID = settings.codeTheme
    let styled = await withTaskGroup(of: (CodeLanguage, AttributedString).self) { group in
      for sample in content.codeSamples {
        group.addTask {
          (sample.language, await CodeHighlighter.highlight(sample.source, themeID: themeID))
        }
      }
      var styled: [CodeLanguage: AttributedString] = [:]
      for await (language, attributed) in group {
        styled[language] = attributed
      }
      return styled
    }
    highlighted = styled
    plainSamples = styled.mapValues { String($0.characters) }
    #if DEBUG
      appliedThemeID = themeID
    #endif
  }

  private var descriptionColumn: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(String(localized: "Description", bundle: .module)).font(.title2.bold())
      if contentLoading {
        ProgressView(String(localized: "Loading description…", bundle: .module))
      } else if let description = content?.description {
        Markdown(description).lineSpacing(1.75)
          .accessibilityIdentifier("algorithmDescriptionText")
      } else if !contentUnavailable {
        Text(String(localized: "No description available yet.", bundle: .module)).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var complexityColumn: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(String(localized: "Complexity", bundle: .module)).font(.title2.bold())
      complexityGrid

      GrowthModelComparisonSection(algorithm: algorithm)
        .padding(.top, 8)

      Text(String(localized: "Big-O Correlation", bundle: .module)).font(.title2.bold()).padding(.top, 8)
      BigOCorrelationChart(algorithm: algorithm, refreshRevision: analyticsRevision)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Use one column in a narrow detail pane so common bounds fit without horizontal scrolling.
  /// Wider panes retain the compact 2x2 layout (best/average over worst/space).
  ///
  /// Each `GridRow` uses `alignment: .bottom`, not the Grid default `.center` -- two equations of
  /// different rendered heights in the same row (e.g. "O(n log² n)"'s superscript-tall box next to
  /// "O(1)"'s short one) land on visibly different baselines under center alignment, since
  /// centering a short box inside the row's full height sits its glyphs at a different vertical
  /// offset than a tall box's glyphs at that same center. Bottom-aligning instead lines up each
  /// equation's own (roughly consistent, since none of these have deep subscripts) descent.
  @ViewBuilder
  private var complexityGrid: some View {
    if availableWidth < 500 {
      VStack(alignment: .leading, spacing: 8) {
        ForEach(["best", "average", "worst", "space"], id: \.self) { id in
          LabeledEquationCell(label: complexityRow(id).label, equation: complexityRow(id).latex)
        }
        LabeledEquationCell(
          label: String(localized: "Implementation Complexity", bundle: .module),
          equation: "\(algorithm.metadata.implementationComplexity)"
        )
      }
      .accessibilityIdentifier("complexityEquationGrid")
    } else {
      Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
        GridRow(alignment: .bottom) {
          LabeledEquationCell(label: complexityRow("best").label, equation: complexityRow("best").latex)
          LabeledEquationCell(label: complexityRow("average").label, equation: complexityRow("average").latex)
        }
        GridRow(alignment: .bottom) {
          LabeledEquationCell(label: complexityRow("worst").label, equation: complexityRow("worst").latex)
          LabeledEquationCell(label: complexityRow("space").label, equation: complexityRow("space").latex)
        }
        // The implementation score spans both columns in the wider layout.
        GridRow(alignment: .bottom) {
          LabeledEquationCell(
            label: String(localized: "Implementation Complexity", bundle: .module),
            equation: "\(algorithm.metadata.implementationComplexity)"
          )
          .gridCellColumns(2)
        }
      }
      .accessibilityIdentifier("complexityEquationGrid")
    }
  }

  private func complexityRow(_ id: String) -> ComplexityRow {
    let rows = algorithm.metadata.complexityRows
    return rows.first { $0.id == id } ?? rows[0]
  }
}

struct CodeDiscoveryTip: Tip {
  @Parameter static var hasExploredCode: Bool = false

  var title: Text { Text(String(localized: "Explore the implementation", bundle: .module)) }
  var message: Text? {
    Text(String(localized: "Choose a language to read its reference code, or copy the full sample with Copy Code.", bundle: .module))
  }
  var rules: [Rule] {
    #Rule(Self.$hasExploredCode) { $0 == false }
  }
  var options: [any Option] {
    MaxDisplayCount(2)
    IgnoresDisplayFrequency(true)
  }
}

private extension View {
  /// Same Liquid Glass convention as `RunControlBar.glassOrMaterialBackground()` — the app
  /// builds against the iOS 26 SDK but ships back to iOS 18.0 (`Module.deploymentTargets`), so
  /// every Liquid Glass site needs this `#available` fallback, not just this one.
  @ViewBuilder
  func glassOrMaterialBackground() -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(.regular.interactive(), in: .circle)
    } else {
      background(.thinMaterial, in: Circle())
    }
  }
}
