/// An ID only, mirroring `VisualizerID`'s shape — real theme rendering (colors, syntax rules)
/// stays deferred to whenever `DesignSystemKit` gets real content; no phase currently owns that
/// work, so `SettingsKit` shouldn't depend on it just to persist a chosen theme's name.
public struct CodeThemeID: Hashable, Sendable, Codable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension CodeThemeID {
    /// The six themes `Legacy/Shared/Views/Code/Themes/CodeThemes.swift` ships — kept here as the
    /// known set for `SettingsView`'s picker, even though the themes themselves aren't ported yet.
    public static let knownIDs: [CodeThemeID] = [
        CodeThemeID(rawValue: "monokai"),
        CodeThemeID(rawValue: "pygments"),
        CodeThemeID(rawValue: "arduino"),
        CodeThemeID(rawValue: "colorful"),
        CodeThemeID(rawValue: "dracula"),
        CodeThemeID(rawValue: "emacs"),
    ]

    public var displayName: String {
        switch rawValue {
        case "monokai": "Monokai"
        case "pygments": "Pygments"
        case "arduino": "Arduino"
        case "colorful": "Colorful"
        case "dracula": "Dracula"
        case "emacs": "Emacs"
        default: rawValue.capitalized
        }
    }
}
