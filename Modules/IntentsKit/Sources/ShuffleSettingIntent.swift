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
            categoryName: "Sort Symphony")
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
