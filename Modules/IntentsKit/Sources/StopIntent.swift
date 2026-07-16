import AppIntents
import SortFeature

/// The App Intents equivalent of the automation banner's Stop button — a no-op, not an error, if
/// nothing is currently open or nothing is running.
public struct StopIntent: AppIntent {
    public static var title: LocalizedStringResource { "Stop" }
    public static var description: IntentDescription {
        IntentDescription(
            "Stops whichever run or automation sweep is currently in progress in Sort Symphony.",
            categoryName: "Sort Symphony",
            searchKeywords: ["Stop Sort", "Cancel", "Halt"])
    }

    public static var openAppWhenRun: Bool { true }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        SortCoordinator.shared.stop()
        return .result()
    }
}
