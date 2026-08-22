import AlgorithmKit
import AppIntents

/// Same shape as `AlgorithmEntity`/`VisualizerEntity` — a `Sendable` snapshot of any
/// `ShuffleAlgorithm`, resolved back to the real conformance through `ShuffleRegistry` by `id`.
public struct ShuffleEntity: AppEntity {
  public let id: String
  public let displayName: String

  public init(shuffle: any ShuffleAlgorithm) {
    id = shuffle.id.rawValue
    displayName = shuffle.metadata.displayName
  }

  public var shuffleID: ShuffleID { ShuffleID(rawValue: id) }

  public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Shuffle" }
  public static let defaultQuery = ShuffleEntityQuery()

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(displayName)")
  }
}

public struct ShuffleEntityQuery: EntityQuery, EnumerableEntityQuery {
  public init() {}

  @MainActor
  public func entities(for identifiers: [String]) async -> [ShuffleEntity] {
    identifiers.compactMap { rawID in
      ShuffleRegistry.shared.shuffle(id: ShuffleID(rawValue: rawID)).map(ShuffleEntity.init)
    }
  }

  @MainActor
  public func suggestedEntities() async -> [ShuffleEntity] {
    await allEntities()
  }

  @MainActor
  public func allEntities() async -> [ShuffleEntity] {
    ShuffleRegistry.shared.shuffles
      .sorted { $0.metadata.displayName < $1.metadata.displayName }
      .map(ShuffleEntity.init)
  }
}
