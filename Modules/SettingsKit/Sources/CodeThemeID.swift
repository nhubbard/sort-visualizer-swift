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
    CodeThemeID(rawValue: "zenburn"),
  ]

  public var displayName: String {
    switch rawValue {
    case "monokai": "Monokai"
    case "pygments": "Pygments"
    case "arduino": "Arduino"
    case "colorful": "Colorful"
    case "dracula": "Dracula"
    case "emacs": "Emacs"
    case "abap": "ABAP"
    case "algol": "Algol"
    case "algol_nu": "Algol Nu"
    case "autumn": "Autumn"
    case "borland": "Borland"
    case "bw": "BW"
    case "coffee": "Coffee"
    case "friendly": "Friendly"
    case "friendly_grayscale": "Friendly Grayscale"
    case "fruity": "Fruity"
    case "github-dark": "GitHub Dark"
    case "gruvbox-dark": "Gruvbox Dark"
    case "gruvbox-light": "Gruvbox Light"
    case "igor": "Igor"
    case "inkpot": "Inkpot"
    case "lightbulb": "Lightbulb"
    case "lilypond": "Lilypond"
    case "lovelace": "Lovelace"
    case "manni": "Manni"
    case "material": "Material"
    case "murphy": "Murphy"
    case "native": "Native"
    case "nord": "Nord"
    case "nord-darker": "Nord Darker"
    case "one-dark": "One Dark"
    case "paraiso-dark": "Paraiso Dark"
    case "paraiso-light": "Paraiso Light"
    case "pastie": "Pastie"
    case "perldoc": "Perldoc"
    case "rainbow_dash": "Rainbow Dash"
    case "rrt": "RRT"
    case "sas": "SAS"
    case "solarized-dark": "Solarized Dark"
    case "solarized-light": "Solarized Light"
    case "staroffice": "StarOffice"
    case "stata-dark": "Stata Dark"
    case "stata-light": "Stata Light"
    case "tango": "Tango"
    case "trac": "Trac"
    case "vim": "Vim"
    case "vs": "Visual Studio"
    case "xcode": "Xcode"
    case "zenburn": "Zenburn"
    default: rawValue.capitalized
    }
  }
}
