import AlgorithmKit
import DesignSystemKit
import MarkdownUI
import MathRenderingKit
import SettingsKit
import SwiftUI

/// The `AlgorithmDetailSection(entry:)` §4.2 of ARCHITECTURE_V2.md describes as sitting below the
/// live sort — description + complexity (rendered via `MathView`, derived from
/// `AlgorithmMetadata` directly so all 20 algorithms have it, not just the ones with legacy
/// content) + a language-picker code sample, when `AlgorithmDetailContent` has any.
public struct AlgorithmDetailSection: View {
    private let algorithm: any SortAlgorithm
    private let content: AlgorithmDetailContent?
    /// `ScrollingSortView.body`'s own top-level `GeometryReader` (otherwise only used to size
    /// `SortView`'s frame) passed straight through — not `ViewThatFits`: `descriptionColumn`/
    /// `complexityColumn` below both use `.frame(maxWidth: .infinity)`, which happily shrinks to
    /// any width, so `ViewThatFits` would never actually detect an overflow to fall back from.
    private let availableWidth: CGFloat
    @Environment(AppSettings.self) private var settings
    @State private var selectedLanguage: CodeLanguage = CodeLanguage.all[0]

    /// Below this, `descriptionColumn`/`complexityColumn` stack instead of sitting side by side —
    /// comfortably under a landscape detail pane's width, comfortably over a narrow portrait one's.
    private static let stackedLayoutThreshold: CGFloat = 700

    public init(algorithm: any SortAlgorithm, availableWidth: CGFloat) {
        self.algorithm = algorithm
        self.availableWidth = availableWidth
        content = AlgorithmDetailContent.load(for: algorithm.id.rawValue)
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

                    if let selected = content.codeSamples.first(where: { $0.language == selectedLanguage }) {
                        // AttributedCodeView sizes to its own intrinsic width (`.fixedSize`), so
                        // left inside this leading-aligned VStack it hugs the left edge instead of
                        // sitting under the wider Description/Complexity content above it.
                        HStack {
                            Spacer(minLength: 0)
                            AttributedCodeView(selected.source, theme: settings.codeTheme.makeTheme())
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
            if let firstLanguage = content?.codeSamples.first?.language {
                selectedLanguage = firstLanguage
            }
        }
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
