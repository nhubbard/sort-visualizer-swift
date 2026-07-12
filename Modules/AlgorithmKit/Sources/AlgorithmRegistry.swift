@MainActor
public final class AlgorithmRegistry {
    public static let shared = AlgorithmRegistry()

    public private(set) var algorithms: [any SortAlgorithm] = []

    /// Every algorithm the app ships — native Swift is the only content path (the JavaScriptCore
    /// scripting backend was removed; it referenced a private API and blocked App Store
    /// submission). `AlgorithmKit` has no visibility into `BuiltInAlgorithms` (that dependency
    /// edge runs the other way), so whoever composes the app is responsible for populating this
    /// before calling `discover()`.
    public var builtIns: [any SortAlgorithm] = []

    public init() {}

    public func discover() {
        algorithms = builtIns
    }

    public func algorithm(id: AlgorithmID) -> (any SortAlgorithm)? {
        algorithms.first { $0.id == id }
    }

    /// Feeds Phase 9's data-driven `ContentView` directly (§4.4) — sorted by display name so the
    /// sidebar's section order doesn't depend on discovery/file-system order.
    public func algorithms(in category: AlgorithmCategory) -> [any SortAlgorithm] {
        algorithms
            .filter { $0.metadata.category == category }
            .sorted { $0.metadata.displayName < $1.metadata.displayName }
    }
}
