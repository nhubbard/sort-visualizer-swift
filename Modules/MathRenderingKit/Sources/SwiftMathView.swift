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
