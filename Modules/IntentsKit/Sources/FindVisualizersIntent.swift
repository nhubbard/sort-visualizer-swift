import AppIntents
import VisualizationKit

/// The "iterate over available visualizers" building block — see `FindAlgorithmsIntent`'s doc
/// comment for the general shape this and its shuffle/automation siblings all share.
public struct FindVisualizersIntent: AppIntent {
    public static var title: LocalizedStringResource { "Find Visualizers" }
    public static var description: IntentDescription {
        IntentDescription("Lists every visualizer Sort Symphony ships.", categoryName: "Sort Symphony")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[VisualizerEntity]> {
        .result(value: VisualizerRegistry.shared.visualizers.map(VisualizerEntity.init))
    }
}
