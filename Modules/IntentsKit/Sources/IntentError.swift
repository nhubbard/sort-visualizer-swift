import AppIntents

/// Only reachable if a Shortcut kept a reference to an `AlgorithmEntity`/`AutomationEntity` from a
/// version of Sort Symphony that has since removed it — the entities themselves are only ever
/// constructed from a live registry entry, never fabricated by hand.
enum SortSymphonyIntentError: Error, CustomLocalizedStringResourceConvertible {
    case algorithmUnavailable
    case automationUnavailable

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .algorithmUnavailable: "That algorithm isn't available anymore."
        case .automationUnavailable: "That automation isn't available anymore."
        }
    }
}
