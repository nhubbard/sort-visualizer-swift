import AppIntents
import SettingsKit
import SortFeature

/// Sets `AppSettings.defaultArraySize` — like `SetShuffleIntent`, this affects the *next* run
/// `ContentView` starts, not one already replaying: `SortSession.arraySize` is fixed by whichever
/// `start(size:)` call began the current run, always clamped into that algorithm's own
/// `sizeRange`. `RunSortIntent` exposes a per-run override for changing it and starting
/// immediately.
public struct SetArraySizeIntent: AppIntent {
    public static var title: LocalizedStringResource { "Set Array Size" }
    public static var description: IntentDescription {
        IntentDescription("Changes the default array size Sort Symphony sorts.", categoryName: "Sort Symphony")
    }

    @Parameter(title: "Size")
    public var size: Int

    public init() {}

    public init(size: Int) {
        self.size = size
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppSettings.shared.defaultArraySize = size
        return .result()
    }
}

/// The App Intents equivalent of the manual size stepper's ⌘S shortcut — only meaningful against
/// whatever sort is currently on screen, so it's a no-op (not an error) if nothing's open.
public struct CycleArraySizeIntent: AppIntent {
    public static var title: LocalizedStringResource { "Cycle Array Size" }
    public static var description: IntentDescription {
        IntentDescription("Advances the array size of whichever sort is currently open in Sort Symphony.", categoryName: "Sort Symphony")
    }

    public static var openAppWhenRun: Bool { true }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        await SortCoordinator.shared.activeSortSession?.cycleArraySize()
        return .result()
    }
}
