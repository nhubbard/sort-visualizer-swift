@MainActor
public final class AlgorithmRegistry {
    public static let shared = AlgorithmRegistry()

    public private(set) var algorithms: [any SortAlgorithm] = []

    /// Escape-hatch native algorithms — empty by default (§2.6: everything is scripted except the
    /// rare case JS genuinely can't express). `AlgorithmKit` has no visibility into
    /// `BuiltInAlgorithms` (that dependency edge runs the other way), so whoever composes the app
    /// is responsible for populating this before calling `discover()`.
    public var builtIns: [any SortAlgorithm] = []

    public init() {}

    /// Script-loading half (`loadScripts(from:)` against the bundled `Algorithms/` directory)
    /// lands in Phase 3 once `ScriptingKit` exists.
    public func discover() {
        algorithms = builtIns
    }
}
