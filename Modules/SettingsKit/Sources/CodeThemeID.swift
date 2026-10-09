import Foundation
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
  /// All 48 styles Pygments ships (`Tools/GenerateThemes/generate_themes.py` generates a
  /// `CodeTheme` for each into `Modules/DesignSystemKit/Sources/Themes/`) — kept here as the
  /// known set for `SettingsView`'s picker.
  public static let knownIDs: [CodeThemeID] = [
    CodeThemeID(rawValue: "monokai"),
    CodeThemeID(rawValue: "pygments"),
    CodeThemeID(rawValue: "arduino"),
    CodeThemeID(rawValue: "colorful"),
    CodeThemeID(rawValue: "dracula"),
    CodeThemeID(rawValue: "emacs"),
    CodeThemeID(rawValue: "abap"),
    CodeThemeID(rawValue: "algol"),
    CodeThemeID(rawValue: "algol_nu"),
    CodeThemeID(rawValue: "autumn"),
    CodeThemeID(rawValue: "borland"),
    CodeThemeID(rawValue: "bw"),
    CodeThemeID(rawValue: "coffee"),
    CodeThemeID(rawValue: "friendly"),
    CodeThemeID(rawValue: "friendly_grayscale"),
    CodeThemeID(rawValue: "fruity"),
    CodeThemeID(rawValue: "github-dark"),
    CodeThemeID(rawValue: "gruvbox-dark"),
    CodeThemeID(rawValue: "gruvbox-light"),
    CodeThemeID(rawValue: "igor"),
    CodeThemeID(rawValue: "inkpot"),
    CodeThemeID(rawValue: "lightbulb"),
    CodeThemeID(rawValue: "lilypond"),
    CodeThemeID(rawValue: "lovelace"),
    CodeThemeID(rawValue: "manni"),
    CodeThemeID(rawValue: "material"),
    CodeThemeID(rawValue: "murphy"),
    CodeThemeID(rawValue: "native"),
    CodeThemeID(rawValue: "nord"),
    CodeThemeID(rawValue: "nord-darker"),
    CodeThemeID(rawValue: "one-dark"),
    CodeThemeID(rawValue: "paraiso-dark"),
    CodeThemeID(rawValue: "paraiso-light"),
    CodeThemeID(rawValue: "pastie"),
    CodeThemeID(rawValue: "perldoc"),
    CodeThemeID(rawValue: "rainbow_dash"),
    CodeThemeID(rawValue: "rrt"),
    CodeThemeID(rawValue: "sas"),
    CodeThemeID(rawValue: "solarized-dark"),
    CodeThemeID(rawValue: "solarized-light"),
    CodeThemeID(rawValue: "staroffice"),
    CodeThemeID(rawValue: "stata-dark"),
    CodeThemeID(rawValue: "stata-light"),
    CodeThemeID(rawValue: "tango"),
    CodeThemeID(rawValue: "trac"),
    CodeThemeID(rawValue: "vim"),
    CodeThemeID(rawValue: "vs"),
    CodeThemeID(rawValue: "xcode"),
    CodeThemeID(rawValue: "zenburn")
  ]

  public var displayName: String {
    switch rawValue {
    case "monokai": String(localized: "Monokai", bundle: .module)
    case "pygments": String(localized: "Pygments", bundle: .module)
    case "arduino": String(localized: "Arduino", bundle: .module)
    case "colorful": String(localized: "Colorful", bundle: .module)
    case "dracula": String(localized: "Dracula", bundle: .module)
    case "emacs": String(localized: "Emacs", bundle: .module)
    case "abap": String(localized: "ABAP", bundle: .module)
    case "algol": String(localized: "Algol", bundle: .module)
    case "algol_nu": String(localized: "Algol Nu", bundle: .module)
    case "autumn": String(localized: "Autumn", bundle: .module)
    case "borland": String(localized: "Borland", bundle: .module)
    case "bw": String(localized: "BW", bundle: .module)
    case "coffee": String(localized: "Coffee", bundle: .module)
    case "friendly": String(localized: "Friendly", bundle: .module)
    case "friendly_grayscale": String(localized: "Friendly Grayscale", bundle: .module)
    case "fruity": String(localized: "Fruity", bundle: .module)
    case "github-dark": String(localized: "GitHub Dark", bundle: .module)
    case "gruvbox-dark": String(localized: "Gruvbox Dark", bundle: .module)
    case "gruvbox-light": String(localized: "Gruvbox Light", bundle: .module)
    case "igor": String(localized: "Igor", bundle: .module)
    case "inkpot": String(localized: "Inkpot", bundle: .module)
    case "lightbulb": String(localized: "Lightbulb", bundle: .module)
    case "lilypond": String(localized: "Lilypond", bundle: .module)
    case "lovelace": String(localized: "Lovelace", bundle: .module)
    case "manni": String(localized: "Manni", bundle: .module)
    case "material": String(localized: "Material", bundle: .module)
    case "murphy": String(localized: "Murphy", bundle: .module)
    case "native": String(localized: "Native", bundle: .module)
    case "nord": String(localized: "Nord", bundle: .module)
    case "nord-darker": String(localized: "Nord Darker", bundle: .module)
    case "one-dark": String(localized: "One Dark", bundle: .module)
    case "paraiso-dark": String(localized: "Paraiso Dark", bundle: .module)
    case "paraiso-light": String(localized: "Paraiso Light", bundle: .module)
    case "pastie": String(localized: "Pastie", bundle: .module)
    case "perldoc": String(localized: "Perldoc", bundle: .module)
    case "rainbow_dash": String(localized: "Rainbow Dash", bundle: .module)
    case "rrt": String(localized: "RRT", bundle: .module)
    case "sas": String(localized: "SAS", bundle: .module)
    case "solarized-dark": String(localized: "Solarized Dark", bundle: .module)
    case "solarized-light": String(localized: "Solarized Light", bundle: .module)
    case "staroffice": String(localized: "StarOffice", bundle: .module)
    case "stata-dark": String(localized: "Stata Dark", bundle: .module)
    case "stata-light": String(localized: "Stata Light", bundle: .module)
    case "tango": String(localized: "Tango", bundle: .module)
    case "trac": String(localized: "Trac", bundle: .module)
    case "vim": String(localized: "Vim", bundle: .module)
    case "vs": String(localized: "Visual Studio", bundle: .module)
    case "xcode": String(localized: "Xcode", bundle: .module)
    case "zenburn": String(localized: "Zenburn", bundle: .module)
    default: rawValue.capitalized
    }
  }
}
