import AlgorithmKit
import DesignSystemKit
import MarkdownUI
import MathRenderingKit
import SettingsKit
import SwiftUI
import UIKit

/// The `AlgorithmDetailSection(entry:)` §4.2 of ARCHITECTURE_V2.md describes as sitting below the
/// live sort — description + complexity (rendered via `MathView`, derived from
/// `AlgorithmMetadata` directly so all 20 algorithms have it, not just the ones with legacy
/// content) + a language-picker code sample, when `AlgorithmDetailContent` has any.
public struct AlgorithmDetailSection: View {
  private let algorithm: any SortAlgorithm
  @State private var content: AlgorithmDetailContent?
  /// `ScrollingSortView.body`'s own top-level `GeometryReader` (otherwise only used to size
  /// `SortView`'s frame) passed straight through — not `ViewThatFits`: `descriptionColumn`/
  /// `complexityColumn` below both use `.frame(maxWidth: .infinity)`, which happily shrinks to
  /// any width, so `ViewThatFits` would never actually detect an overflow to fall back from.
  private let availableWidth: CGFloat
  @Environment(AppSettings.self) private var settings
  @State private var selectedLanguage: CodeLanguage = CodeLanguage.all[0]
  /// Highlighting a sample re-parses its full source and re-styles every attribute run — cheap
  /// once, but `AttributedCodeView(selected.source, theme:)` used to pay that cost again on every
  /// SwiftUI body evaluation of this view, not just on an actual language switch, causing a
  /// visible hitch on the newly-ported, hundreds-of-lines algorithms. Computed once per
  /// `content`/theme change in `highlightAllSamples`, off the main actor, instead.
  @State private var highlighted: [CodeLanguage: AttributedString] = [:]
  @State private var plainSamples: [CodeLanguage: String] = [:]

  /// Below this, `descriptionColumn`/`complexityColumn` stack instead of sitting side by side —
  /// comfortably under a landscape detail pane's width, comfortably over a narrow portrait one's.
  private static let stackedLayoutThreshold: CGFloat = 700

  public init(algorithm: any SortAlgorithm, availableWidth: CGFloat) {
    self.algorithm = algorithm
    self.availableWidth = availableWidth
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 24) {
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

      VStack(alignment: .leading, spacing: 8) {
        Text("Implementations").font(.title2.bold())
        if let content, !content.codeSamples.isEmpty {
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
    .padding(.all, 32)
    .task {
      content = await AlgorithmDetailContent.load(for: algorithm.id.rawValue)
      if let firstLanguage = content?.codeSamples.first?.language {
        selectedLanguage = firstLanguage
      }
      if let content { await highlightAllSamples(content) }
    }
    .onChange(of: settings.codeTheme) {
      if let content { Task { await highlightAllSamples(content) } }
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
      for await (language, attributed) in group { styled[language] = attributed }
      return styled
    }
    highlighted = styled
    plainSamples = styled.mapValues { String($0.characters) }
  }

  private var descriptionColumn: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Description").font(.title2.bold())
      if let description = content?.description {
        Markdown(description).lineSpacing(1.75)
      } else {
        Text("No description available yet.").foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var complexityColumn: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Complexity").font(.title2.bold())
      ForEach(algorithm.metadata.complexityRows) { row in
        MathView(text: row.label, equation: row.latex)
      }

      Text("Big-O Correlation").font(.title2.bold()).padding(.top, 8)
      BigOCorrelationChart(algorithm: algorithm)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

extension View {
  /// Same Liquid Glass convention as `RunControlBar.glassOrMaterialBackground()` — the app
  /// builds against the iOS 26 SDK but ships back to iOS 18.0 (`Module.deploymentTargets`), so
  /// every Liquid Glass site needs this `#available` fallback, not just this one.
  @ViewBuilder
  fileprivate func glassOrMaterialBackground() -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(.regular.interactive(), in: .circle)
    } else {
      background(.thinMaterial, in: Circle())
    }
  }
}
