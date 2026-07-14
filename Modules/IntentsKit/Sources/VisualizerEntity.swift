import AppIntents
import VisualizationKit

/// Same shape as `AlgorithmEntity` — a `Sendable` snapshot of `any Visualizer`, resolved back to
/// the real conformance through `VisualizerRegistry` by `id`.
public struct VisualizerEntity: AppEntity {
    public let id: String
    public let displayName: String
    public let iconName: String

    public init(visualizer: any Visualizer) {
        id = visualizer.id.rawValue
        displayName = visualizer.metadata.displayName
        iconName = visualizer.metadata.iconName
    }

    public var visualizerID: VisualizerID { VisualizerID(rawValue: id) }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Visualizer" }
    public static let defaultQuery = VisualizerEntityQuery()

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)", image: .init(systemName: iconName))
    }
}

public struct VisualizerEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    @MainActor
    public func entities(for identifiers: [String]) async -> [VisualizerEntity] {
        identifiers.compactMap { rawID in
            VisualizerRegistry.shared.visualizer(id: VisualizerID(rawValue: rawID)).map(VisualizerEntity.init)
        }
    }

    @MainActor
    public func suggestedEntities() async -> [VisualizerEntity] {
        await allEntities()
    }

    /// `VisualizerRegistry.visualizers`' own stable, composition-root-defined order — the same one
    /// `AppSettings.cycleVisualizer()` ring-buffers through — not re-sorted alphabetically.
    @MainActor
    public func allEntities() async -> [VisualizerEntity] {
        VisualizerRegistry.shared.visualizers.map(VisualizerEntity.init)
    }
}
