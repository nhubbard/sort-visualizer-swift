@MainActor
public final class AlgorithmRegistry {
    public static let shared = AlgorithmRegistry()

    public private(set) var algorithms: [any SortAlgorithm] = []

    /// Escape-hatch native algorithms — empty by default (§2.6: everything is scripted except the
    /// rare case JS genuinely can't express). `AlgorithmKit` has no visibility into
    /// `BuiltInAlgorithms` (that dependency edge runs the other way), so whoever composes the app
    /// is responsible for populating this before calling `discover()`.
    public var builtIns: [any SortAlgorithm] = []

    /// Same story as `builtIns`, one level removed: the actual JS-loading logic lives in
    /// `ScriptingKit` (it needs `JavaScriptCore`), which `AlgorithmKit` can't depend on without
    /// inverting the module graph. Whoever composes the app sets this to something like
    /// `{ ScriptAlgorithmLoader.loadScripts(from: Bundle.main.url(forResource: "Algorithms", withExtension: nil)!) }`
    /// before calling `discover()`. `nil` by default so a registry with nothing wired up just
    /// yields `builtIns` alone, rather than crashing.
    public var scriptLoader: (() -> [any SortAlgorithm])?

    public init() {}

    public func discover() {
        algorithms = builtIns + (scriptLoader?() ?? [])
    }

    public func algorithm(id: AlgorithmID) -> (any SortAlgorithm)? {
        algorithms.first { $0.id == id }
    }
}
