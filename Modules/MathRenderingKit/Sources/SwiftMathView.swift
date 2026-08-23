@preconcurrency import SwiftMath
import SwiftUI

/// `MTFontManager` (a third-party type, not audited for Swift 6 strict concurrency) isn't
/// `Sendable`, so accessing its `.manager` singleton needs `@preconcurrency import` above to avoid
/// a "reference to class property is not concurrency-safe" error at every access site — a plain
/// `nonisolated(unsafe)` on our own declaration doesn't cover accessing *their* static property.
/// Safe here in practice: the only two access points are `updateUIView`/`updateNSView` below, both
/// MainActor-isolated by `UIViewRepresentable`/`NSViewRepresentable`, and `MTFontManager`'s own
/// `nameToFontMap` is already `@RWLocked` internally.
private let sharedMathFontManager = MTFontManager.manager

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

    /// Without this, SwiftUI's default `UIViewRepresentable` sizing negotiation was letting
    /// `MTMathUILabel` claim however much width/height its container merely *proposed* — a plain
    /// `HStack`/`VStack` row with no other constraint could propose a huge share of the detail
    /// pane's width, and the label expanded to fill it (blowing up that row's, and therefore its
    /// whole column's, ideal width), with knock-on vertical bloat once other layout code reacted
    /// to that width. `MTMathUILabel.intrinsicContentSize` (`_sizeThatFits(CGSizeZero)` internally)
    /// already computes the label's real, tight rendered-content size regardless of what's
    /// proposed -- returning it directly here is what makes the label actually hug its equation.
    public func sizeThatFits(
      _ proposal: ProposedViewSize, uiView: MTMathUILabel, context: Context
    ) -> CGSize? {
      uiView.intrinsicContentSize
    }

    public func updateUIView(_ view: MTMathUILabel, context: Context) {
      view.latex = equation
      // `MTFontManager()` (the plain initializer) starts with an empty `nameToFontMap`, so it
      // reloads the font from disk on every call — `.manager` is SwiftMath's own shared instance
      // (`.fontManager` is the same value but `internal` to the package, inaccessible here),
      // whose cache actually persists across `updateUIView`/`updateNSView` calls. Found via the
      // Full Sweep profiling round that also fixed `AnalyticsService.fetchSummaries`.
      view.font = sharedMathFontManager.font(withName: font.rawValue, size: fontSize)
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

    /// See the iOS variant's identical override above for why this is necessary.
    public func sizeThatFits(
      _ proposal: ProposedViewSize, nsView: MTMathUILabel, context: Context
    ) -> CGSize? {
      nsView.intrinsicContentSize
    }

    public func updateNSView(_ view: MTMathUILabel, context: Context) {
      view.latex = equation
      // `MTFontManager()` (the plain initializer) starts with an empty `nameToFontMap`, so it
      // reloads the font from disk on every call — `.manager` is SwiftMath's own shared instance
      // (`.fontManager` is the same value but `internal` to the package, inaccessible here),
      // whose cache actually persists across `updateUIView`/`updateNSView` calls. Found via the
      // Full Sweep profiling round that also fixed `AnalyticsService.fetchSummaries`.
      view.font = sharedMathFontManager.font(withName: font.rawValue, size: fontSize)
      view.textAlignment = textAlignment
      view.labelMode = labelMode
      view.textColor = MTColor(Color.primary)
      view.contentInsets = insets
    }
  }
#endif
