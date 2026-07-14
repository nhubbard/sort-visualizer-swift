import AlgorithmKit
import AppIntents

/// The "iterate over available shuffles" building block — see `FindAlgorithmsIntent`'s doc comment
/// for the general shape this and its visualizer/automation siblings all share.
public struct FindShufflesIntent: AppIntent {
    public static var title: LocalizedStringResource { "Find Shuffles" }
    public static var description: IntentDescription {
        IntentDescription("Lists every shuffle Sort Symphony ships.", categoryName: "Sort Symphony")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[ShuffleEntity]> {
        let shuffles = ShuffleRegistry.shared.shuffles
            .sorted { $0.metadata.displayName < $1.metadata.displayName }
        return .result(value: shuffles.map(ShuffleEntity.init))
    }
}
