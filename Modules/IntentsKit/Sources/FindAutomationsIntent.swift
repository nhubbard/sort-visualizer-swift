import AppIntents
import SortFeature

/// The "iterate over available automations" building block — see `FindAlgorithmsIntent`'s doc
/// comment for the general shape this and its visualizer/shuffle siblings all share. Today this
/// always returns exactly the two entries ⌘⇧A/⌘⌥⇧A already trigger (Size Sweep, Max Size Only);
/// it stays correct unchanged if more are ever registered in `AutomationRegistry`.
public struct FindAutomationsIntent: AppIntent {
    public static var title: LocalizedStringResource { "Find Automations" }
    public static var description: IntentDescription {
        IntentDescription("Lists Sort Symphony's registered size-sweep automations.", categoryName: "Sort Symphony")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[AutomationEntity]> {
        .result(value: AutomationRegistry.shared.automations.map(AutomationEntity.init))
    }
}
