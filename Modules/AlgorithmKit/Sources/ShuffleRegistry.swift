@MainActor
public final class ShuffleRegistry {
  public static let shared = ShuffleRegistry()

  public private(set) var shuffles: [any ShuffleAlgorithm] = []

  /// Same story as `AlgorithmRegistry.builtIns` — native Swift is the only content path.
  public var builtIns: [any ShuffleAlgorithm] = []

  public init() {}

  public func discover() {
    shuffles = builtIns
  }

  public func shuffle(id: ShuffleID) -> (any ShuffleAlgorithm)? {
    shuffles.first { $0.id == id }
  }
}
