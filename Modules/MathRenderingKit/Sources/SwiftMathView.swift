import SwiftMath
import SwiftUI

/// Ported near-verbatim from `Legacy/Shared/Views/Utilities/SwiftMathView.swift` — a thin
/// `UIViewRepresentable`/`NSViewRepresentable` wrapper over `SwiftMath`'s `MTMathUILabel`.
#if os(iOS)
public struct SwiftMathView: UIViewRepresentable {
    private let equation: String
    private let font: MathFont
    private let textAlignment: MTTextAlignment
    private let fontSize: CGFloat
    private let labelMode: MTMathUILabelMode
    private let insets: MTEdgeInsets

    public init(
        equation: String,
        font: MathFont = .latinModernFont,
        textAlignment: MTTextAlignment = .center,
        fontSize: CGFloat = 30,
        labelMode: MTMathUILabelMode = .text,
        insets: MTEdgeInsets = MTEdgeInsets()
    ) {
        self.equation = equation
        self.font = font
        self.textAlignment = textAlignment
        self.fontSize = fontSize
        self.labelMode = labelMode
        self.insets = insets
    }

    public func makeUIView(context: Context) -> MTMathUILabel {
        MTMathUILabel()
    }

    public func updateUIView(_ view: MTMathUILabel, context: Context) {
        view.latex = equation
        view.font = MTFontManager().font(withName: font.rawValue, size: fontSize)
        view.textAlignment = textAlignment
        view.labelMode = labelMode
        view.textColor = MTColor(Color.primary)
        view.contentInsets = insets
    }
}
#else
public struct SwiftMathView: NSViewRepresentable {
    private let equation: String
    private let font: MathFont
    private let textAlignment: MTTextAlignment
    private let fontSize: CGFloat
    private let labelMode: MTMathUILabelMode
    private let insets: MTEdgeInsets

    public init(
        equation: String,
        font: MathFont = .latinModernFont,
        textAlignment: MTTextAlignment = .center,
        fontSize: CGFloat = 30,
        labelMode: MTMathUILabelMode = .text,
        insets: MTEdgeInsets = MTEdgeInsets()
    ) {
        self.equation = equation
        self.font = font
        self.textAlignment = textAlignment
        self.fontSize = fontSize
        self.labelMode = labelMode
        self.insets = insets
    }

    public func makeNSView(context: Context) -> MTMathUILabel {
        MTMathUILabel()
    }

    public func updateNSView(_ view: MTMathUILabel, context: Context) {
        view.latex = equation
        view.font = MTFontManager().font(withName: font.rawValue, size: fontSize)
        view.textAlignment = textAlignment
        view.labelMode = labelMode
        view.textColor = MTColor(Color.primary)
        view.contentInsets = insets
    }
}
#endif
