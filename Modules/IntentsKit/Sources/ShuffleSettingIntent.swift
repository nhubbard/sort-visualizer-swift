import AppIntents
import SettingsKit

/// Sets `AppSettings.defaultShuffleID` — unlike the visualizer, a shuffle is a one-shot
/// `SortSession` constructor argument (`ContentView.detailContent` reads it when building a fresh
/// `ScrollingSortView`), so this affects the *next* run, not one already replaying. `RunSortIntent`
/// exposes a per-run override for anyone who needs to change it and start immediately.
public struct SetShuffleIntent: AppIntent {
    public static var title: LocalizedStringResource { "Set Shuffle" }
    public static var description: IntentDescription {
        IntentDescription("Changes which shuffle Sort Symphony scrambles the array with before each run.", categoryName: "Sort Symphony")
    }

    @Parameter(title: "Shuffle")
    public var shuffle: ShuffleEntity

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
