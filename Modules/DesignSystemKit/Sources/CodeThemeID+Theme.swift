import SettingsKit

/// `SettingsKit.CodeThemeID` is an ID only (so `SettingsKit` doesn't need to depend on the actual
/// theme rendering) — this is the other half, mapping that ID to a concrete `CodeTheme` wherever
/// the rendering actually happens.
extension CodeThemeID {
    public func makeTheme() -> any CodeTheme {
        switch rawValue {
        case "monokai": MonokaiTheme()
        case "pygments": PygmentsTheme()
        case "arduino": ArduinoTheme()
        case "colorful": ColorfulTheme()
        case "dracula": DraculaTheme()
        case "emacs": EmacsTheme()
        default: MonokaiTheme()
        }
    }
}
