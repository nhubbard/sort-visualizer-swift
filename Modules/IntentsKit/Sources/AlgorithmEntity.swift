import AlgorithmKit
import AppIntents

/// A Shortcuts-facing stand-in for `any SortAlgorithm` — `AppEntity` needs a plain `Sendable`
/// value type, not an existential protocol, so this snapshots exactly the fields any intent or
/// picker actually needs to display or resolve back to a real algorithm via `AlgorithmRegistry`.
public struct AlgorithmEntity: AppEntity {
    public let id: String
    public let displayName: String
    public let iconName: String
    public let categoryDisplayName: String

    public init(algorithm: any SortAlgorithm) {
        id = algorithm.id.rawValue
        displayName = algorithm.metadata.displayName
        iconName = algorithm.metadata.iconName
        categoryDisplayName = algorithm.metadata.category.displayName
    }

    public var algorithmID: AlgorithmID { AlgorithmID(rawValue: id) }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Sorting Algorithm" }
    public static let defaultQuery = AlgorithmEntityQuery()

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)", subtitle: "\(categoryDisplayName)", image: .init(systemName: iconName))
    }
}

public struct AlgorithmEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    @MainActor
    public func entities(for identifiers: [String]) async -> [AlgorithmEntity] {
        identifiers.compactMap { rawID in
            AlgorithmRegistry.shared.algorithm(id: AlgorithmID(rawValue: rawID)).map(AlgorithmEntity.init)
        }
    }

    @MainActor
    public func suggestedEntities() async -> [AlgorithmEntity] {
        await allEntities()
    }

    /// Backs both the picker's "show everything" list and the system's automatic "Find Sorting
    /// Algorithms" action — the same alphabetical-by-`displayName` order `AlgorithmRegistry.
    /// algorithms(in:)` already sorts the sidebar by.
    @MainActor
    public func allEntities() async -> [AlgorithmEntity] {
        AlgorithmRegistry.shared.algorithms
            .sorted { $0.metadata.displayName < $1.metadata.displayName }
            .map(AlgorithmEntity.init)
    }
}
