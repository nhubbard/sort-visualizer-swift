import AlgorithmKit
import DesignSystemKit
import MarkdownUI
import MathRenderingKit
import SettingsKit
import SwiftUI
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
    showImplementations: Bool = true
  ) {
    self.algorithm = algorithm
    self.availableWidth = availableWidth
    self.analyticsRevision = analyticsRevision
    self.showImplementations = showImplementations
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
          "Reference content unavailable", systemImage: "doc.questionmark",
          description: Text(
            "The bundled algorithm details could not be loaded. Reinstall the app to restore descriptions and code examples."
          )
        )
        .accessibilityIdentifier("algorithmDetailsLoadError")
      }
      if availableWidth < Self.stackedLayoutThreshold {
        VStack(alignment: .leading, spacing: 24) {
          descriptionColumn
          complexityColumn
        }
      } else {
        HStack(alignment: .top, spacing: 16) {
          descriptionColumn
          complexityColumn
        }
      }

      if showImplementations && !contentUnavailable {
        VStack(alignment: .leading, spacing: 8) {
          Text("Implementations").font(.title2.bold())
          if contentLoading {
            ProgressView("Loading code examples…")
          } else if let content, !content.codeSamples.isEmpty {
            Picker("Language", selection: $selectedLanguage) {
              ForEach(content.codeSamples, id: \.language) { sample in
                Text(sample.language.title).tag(sample.language)
              }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("codeLanguagePicker")

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
                  .overlay(alignment: .topTrailing) {
                    if let plain = plainSamples[selectedLanguage] {
                      Button {
                        UIPasteboard.general.string = plain
                      } label: {
                        Image(systemName: "doc.on.doc")
                          .padding(8)
                          .glassOrMaterialBackground()
                      }
                      .buttonStyle(.plain)
                      .offset(x: 8, y: -8)
                      .accessibilityLabel("Copy Code")
                    }
                  }
                } else {
                  ProgressView()
                    .frame(minWidth: 200, minHeight: 100)
                }
                Spacer(minLength: 0)
              }
            }
          } else {
            Text("No code samples available yet.").foregroundStyle(.secondary)
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
      Text("Description").font(.title2.bold())
      if contentLoading {
        ProgressView("Loading description…")
      } else if let description = content?.description {
        Markdown(description).lineSpacing(1.75)
          .accessibilityIdentifier("algorithmDescriptionText")
      } else if !contentUnavailable {
        Text("No description available yet.").foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var complexityColumn: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Complexity").font(.title2.bold())
      complexityGrid

      GrowthModelComparisonSection(algorithm: algorithm)
        .padding(.top, 8)

      Text("Big-O Correlation").font(.title2.bold()).padding(.top, 8)
      BigOCorrelationChart(algorithm: algorithm, refreshRevision: analyticsRevision)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// 2x2 (best/average over worst/space), not a single column of four full-width
  /// `LabeledEquationCell`s -- each cell's own label is small and secondary-styled instead of a
  /// full label column, which keeps this section compact instead of stacking four full-width rows
  /// underneath "Complexity".
  ///
  /// Each `GridRow` uses `alignment: .bottom`, not the Grid default `.center` -- two equations of
  /// different rendered heights in the same row (e.g. "O(n log² n)"'s superscript-tall box next to
  /// "O(1)"'s short one) land on visibly different baselines under center alignment, since
  /// centering a short box inside the row's full height sits its glyphs at a different vertical
  /// offset than a tall box's glyphs at that same center. Bottom-aligning instead lines up each
  /// equation's own (roughly consistent, since none of these have deep subscripts) descent.
  private var complexityGrid: some View {
    let rows = algorithm.metadata.complexityRows
    func row(_ id: String) -> ComplexityRow {
      rows.first { $0.id == id } ?? rows[0]
    }
    return Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
      GridRow(alignment: .bottom) {
        LabeledEquationCell(label: row("best").label, equation: row("best").latex)
        LabeledEquationCell(label: row("average").label, equation: row("average").latex)
      }
      GridRow(alignment: .bottom) {
        LabeledEquationCell(label: row("worst").label, equation: row("worst").latex)
        LabeledEquationCell(label: row("space").label, equation: row("space").latex)
      }
      // Not another equation -- a plain integer, rendered through the same cell anyway (a bare
      // number is valid LaTeX) so it lines up visually with best/average/worst/space instead of
      // introducing a differently-styled row. Spans both columns: there's no natural second stat
      // to pair it with. The actual point of showing this next to Big-O: a higher score here
      // doesn't imply a worse growth curve above -- e.g. Quadsort's port is one of the most
      // complex in the app but among the fastest in practice.
      GridRow(alignment: .bottom) {
        LabeledEquationCell(
          label: "Implementation Complexity",
          equation: "\(algorithm.metadata.implementationComplexity)"
        )
        .gridCellColumns(2)
      }
    }
    .accessibilityIdentifier("complexityEquationGrid")
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
