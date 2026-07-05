import SwiftUI

/// Ported from `Legacy/Shared/Views/Code/AttributedCodeView.swift`'s `AttributedCode` — renamed to
/// avoid colliding with the type named `Code` elsewhere, and taking its theme as an explicit
/// parameter (driven by `AppSettings.codeTheme`) instead of reading `@AppStorage("sortCodeViewTheme")`
/// directly, since `DesignSystemKit` shouldn't own that persistence decision.
public struct AttributedCodeView: View {
    private let attributedString: AttributedString
    private let backgroundColor: Color

    public init(_ source: String, theme: any CodeTheme) {
        backgroundColor = theme.getBgColor()
        var attrString = AttributedString(localized: String.LocalizationValue(source), including: \.sortSymphonyApp)
        for run in attrString.runs {
            guard let codeMode = run.code else { continue }
            attrString[run.range].mergeAttributes(applyTextFormat(theme.getFormat(token: codeMode)))
        }
        attributedString = attrString
    }

    public var body: some View {
        Text(attributedString)
            .padding()
            .fixedSize(horizontal: true, vertical: true)
            .background(backgroundColor)
            .cornerRadius(15)
            .textSelection(.enabled)
    }
}
