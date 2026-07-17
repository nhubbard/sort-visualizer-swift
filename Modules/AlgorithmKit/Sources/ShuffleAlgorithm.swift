import SortEngineKit

/// ArrayV treats shuffling as *just another algorithm* — it runs through the same instrumentation
/// a sort does, which is why "watch a fractal shuffle un-scramble" is a real, working feature
/// there (§2A.4). Starts from a sorted/identity array, same primitive surface as `SortAlgorithm`.
public protocol ShuffleAlgorithm: Sendable {
  var id: ShuffleID { get }
  var metadata: ShuffleMetadata { get }
  func record(into engine: inout RecordingEngine)
}

public struct ShuffleID: Hashable, Sendable, Codable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct ShuffleMetadata: Sendable, Codable, Equatable {
  public var displayName: String

  public init(displayName: String) {
    self.displayName = displayName
  }
}
