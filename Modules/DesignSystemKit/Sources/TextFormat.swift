import SwiftUI
import Then

/// Ported near-verbatim from `Legacy/Shared/Views/Code/TextFormat.swift` — a builder for the
/// per-token styling every `CodeTheme` produces, applied to an `AttributedString` run via
/// `applyTextFormat(_:)` below.
public struct TextFormat {
    public var fg: Color = .white
    public var bg: Color = .black
    public var bold: Bool = false
    public var italic: Bool = false
    public var underline: Bool = false
}

extension TextFormat {
    public final class Builder {
        private var _bg: Color
        private var _fg: Color = .white
        private var _bold: Bool = false
        private var _italic: Bool = false
        private var _underline: Bool = false

        init(_ bg: Color) {
            _bg = bg
        }

        @discardableResult
        public func fg(_ fg: String) -> TextFormat.Builder {
            _fg = Color(fromHex: fg) ?? .white
            return self
        }

        @discardableResult
        public func fg(_ fg: Color) -> TextFormat.Builder {
            _fg = fg
            return self
        }

        /// Ported with the parameter bug fixed — `Legacy/`'s `bg(_ bg: Color = .white)` always
        /// set white regardless of what was passed in; several themes (Colorful's error case,
        /// Dracula/Emacs's fallback) rely on an actual background override taking effect.
        @discardableResult
        public func bg(_ bg: String) -> TextFormat.Builder {
            _bg = Color(fromHex: bg) ?? _bg
            return self
        }

        @discardableResult
        public func bg(_ bg: Color) -> TextFormat.Builder {
            _bg = bg
            return self
        }

        @discardableResult
        public func bold() -> TextFormat.Builder {
            _italic = false
            _bold = true
            return self
        }

        @discardableResult
        public func italic() -> TextFormat.Builder {
            _bold = false
            _italic = true
            return self
        }

        @discardableResult
        public func underline() -> TextFormat.Builder {
            _underline = true
            return self
        }

        public func build() -> TextFormat {
            TextFormat(fg: _fg, bg: _bg, bold: _bold, italic: _italic, underline: _underline)
        }
    }

    public static func getBuilder(bg: Color) -> Builder {
        TextFormat.Builder(bg)
    }
}

extension TextFormat.Builder: Then {}

private typealias UIAttr = AttributeScopes.SwiftUIAttributes
private typealias UIForeground = UIAttr.ForegroundColorAttribute
private typealias UIBackground = UIAttr.BackgroundColorAttribute
private typealias UIFont = UIAttr.FontAttribute
private typealias UIUnderline = UIAttr.UnderlineStyleAttribute

public func applyTextFormat(_ format: TextFormat) -> AttributeContainer {
    let baseFont: Font = .system(size: 12, weight: .regular, design: .monospaced)
    var container = AttributeContainer()
    container[UIForeground.self] = format.fg
    container[UIBackground.self] = format.bg
    if format.bold && !format.italic {
        container[UIFont.self] = baseFont.bold()
    } else if !format.bold && format.italic {
        container[UIFont.self] = baseFont.italic()
    } else if format.bold && format.italic {
        container[UIFont.self] = baseFont.bold().italic()
    } else {
        container[UIFont.self] = baseFont
    }
    if format.underline {
        container[UIUnderline.self] = .single
    }
    return container
}
