import AlgorithmKit
import AppIntents
import SettingsKit

/// Sets `AppSettings.defaultShuffleID` — unlike the visualizer, a shuffle is a one-shot
/// `SortSession` constructor argument (`ContentView.detailContent` reads it when building a fresh
/// `ScrollingSortView`), so this affects the *next* run, not one already replaying. `RunSortIntent`
/// exposes a per-run override for anyone who needs to change it and start immediately. Named
/// "Default" (see `SetArraySizeIntent`'s identical reasoning) so it doesn't read as "changes
/// whatever's currently running."
public struct SetShuffleIntent: AppIntent {
  public static var title: LocalizedStringResource { "Set Default Shuffle" }
  public static var description: IntentDescription {
    IntentDescription(
      "Changes the default shuffle Sort Symphony scrambles the array with — takes effect on the next run, not one already on screen.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Shuffle", "Default Shuffle", "Scramble"])
  }

  @Parameter(title: "Shuffle", description: "The default shuffle for future runs.")
  public var shuffle: ShuffleEntity

  public static var parameterSummary: some ParameterSummary {
    Summary("Set default shuffle to \(\.$shuffle)")
  }

  public init() {}

  public init(shuffle: ShuffleEntity) {
    self.shuffle = shuffle
  }

  @MainActor
  public func perform() async throws -> some IntentResult {
    AppSettings.shared.defaultShuffleID = shuffle.shuffleID
    return .result()
  }
}

/// The value-returning counterpart to `AppSettings.cycleShuffle()` (`CycleVisualizerIntent`'s own
/// shape, one level up) — advances `defaultShuffleID` one step around the ring buffer and hands
/// back the shuffle it landed on, so a Shortcut can feed that straight into `RunSortIntent`'s
/// `shuffle` parameter as a variable instead of a fixed literal. Built for exactly this: chaining
/// "Get Next Shuffle" → "Run Sort" inside a loop cycles through every shuffle over a long run,
/// without Shortcuts ever needing to iterate `FindShufflesIntent`'s own list itself.
public struct GetNextShuffleIntent: AppIntent {
  public static var title: LocalizedStringResource { "Get Next Shuffle" }
  public static var description: IntentDescription {
    IntentDescription(
      "Advances Sort Symphony's default shuffle by one step and returns it — chain with Run Sort to cycle through every shuffle over a long run.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Next Shuffle", "Cycle Shuffle", "Shuffle"],
      resultValueName: "Shuffle")
  }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<ShuffleEntity> {
    AppSettings.shared.cycleShuffle()
    let shuffles = ShuffleRegistry.shared.shuffles.sorted {
      $0.metadata.displayName < $1.metadata.displayName
    }
    let shuffle =
      ShuffleRegistry.shared.shuffle(id: AppSettings.shared.defaultShuffleID) ?? shuffles.first
    guard let shuffle else { throw SortSymphonyIntentError.shuffleUnavailable }
    return .result(value: ShuffleEntity(shuffle: shuffle))
  }
}
