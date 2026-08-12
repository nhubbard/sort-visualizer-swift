import AppIntents

/// Only reachable if a Shortcut kept a reference to an `AlgorithmEntity`/`AutomationEntity` from a
/// version of Sort Symphony that has since removed it — the entities themselves are only ever
/// constructed from a live registry entry, never fabricated by hand.
enum SortSymphonyIntentError: Error, CustomLocalizedStringResourceConvertible {
  case algorithmUnavailable
  case automationUnavailable
  /// Thrown by live-session-only intents (e.g. `CycleArraySizeIntent`) instead of silently
  /// no-op'ing when `SortCoordinator.activeSortSession` is `nil` — open a sort in Sort Symphony
  /// first (e.g. via `RunSortIntent`), since there's nothing else this could act on.
  case noActiveSession
  /// Unreachable in practice — `GetNextShuffleIntent`/`GetNextVisualizerIntent` only ever look up
  /// an ID they just read straight back out of the same live registry that produced it, same as
  /// `.algorithmUnavailable`'s own doc comment. Kept as a real guard rather than force-unwrapping.
  case shuffleUnavailable
  case visualizerUnavailable

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .algorithmUnavailable: "That algorithm isn't available anymore."
    case .automationUnavailable: "That automation isn't available anymore."
    case .noActiveSession: "No sort is currently open in Sort Symphony."
    case .shuffleUnavailable: "No shuffles are currently available."
    case .visualizerUnavailable: "No visualizers are currently available."
    }
  }
}
