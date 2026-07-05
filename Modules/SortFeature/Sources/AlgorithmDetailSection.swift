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
    @Environment(AppSettings.self) private var settings
    @State private var selectedLanguage: CodeLanguage = CodeLanguage.all[0]

    public init(algorithm: any SortAlgorithm) {
        self.algorithm = algorithm
        content = AlgorithmDetailContent.load(for: algorithm.id.rawValue)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Description").font(.title2.bold())
                    if let description = content?.description {
                        Markdown(description).lineSpacing(1.75)
                    } else {
                        Text("No description available yet.").foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Complexity").font(.title2.bold())
                    ForEach(algorithm.metadata.complexityRows) { row in
                        MathView(text: row.label, equation: row.latex)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                        AttributedCodeView(selected.source, theme: settings.codeTheme.makeTheme())
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
}
