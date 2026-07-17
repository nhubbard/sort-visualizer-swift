import AppIntents
import SettingsKit
import SortFeature

/// Sets `AppSettings.playbackSpeed` (the default every *new* `SortSession` seeds its `ReplayEngine.
/// speed` from) and, if a sort is already open, also nudges that live `ReplayEngine` directly —
/// closing the one real gap in `AppSettings`-only intents: `ReplayEngine.speed` is a live value a
/// running session never writes back to `AppSettings`, so without this an already-playing sort
/// would ignore the change until its next run.
public struct SetPlaybackSpeedIntent: AppIntent {
  public static var title: LocalizedStringResource { "Set Playback Speed" }
  public static var description: IntentDescription {
    IntentDescription(
      "Changes how fast Sort Symphony plays back a sort, in operations per second.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Speed", "Playback Speed", "Faster", "Slower"])
  }

  @Parameter(
    title: "Speed (ops/sec)",
    description: "How many sort operations to play back per second — higher is faster.")
  public var speed: Double

  public static var parameterSummary: some ParameterSummary {
    Summary("Set playback speed to \(\.$speed) operations per second")
  }

  public init() {}

  public init(speed: Double) {
    self.speed = speed
  }

  @MainActor
  public func perform() async throws -> some IntentResult {
    AppSettings.shared.playbackSpeed = speed
    SortCoordinator.shared.activeSortSession?.lastReplay?.speed = speed
    return .result()
  }
}

/// Sets `AppSettings.soundEnabled` (the default every *new* `SortSession` seeds its own,
/// session-local `soundEnabled` from — see that property's own doc comment) and, if a sort is
/// already open, also nudges that session's live flag directly, same reasoning as
/// `SetPlaybackSpeedIntent` above.
public struct SetSoundEnabledIntent: AppIntent {
  public static var title: LocalizedStringResource { "Set Sound" }
  public static var description: IntentDescription {
    IntentDescription(
      "Turns Sort Symphony's sort playback sound on or off.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Sound", "Mute", "Unmute", "Audio"])
  }

  @Parameter(title: "Enabled", description: "Whether sort playback sound should be on.")
  public var enabled: Bool

  public static var parameterSummary: some ParameterSummary {
    Summary("Set sound \(\.$enabled)")
  }

  public init() {}

  public init(enabled: Bool) {
    self.enabled = enabled
  }

  @MainActor
  public func perform() async throws -> some IntentResult {
    AppSettings.shared.soundEnabled = enabled
    SortCoordinator.shared.activeSortSession?.soundEnabled = enabled
    return .result()
  }
}
