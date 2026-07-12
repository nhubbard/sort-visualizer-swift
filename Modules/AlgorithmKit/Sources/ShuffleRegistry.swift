@MainActor
public final class ShuffleRegistry {
    public static let shared = ShuffleRegistry()

    public private(set) var shuffles: [any ShuffleAlgorithm] = []

    /// Same escape-hatch story as `AlgorithmRegistry.builtIns` — empty by default (§2.6).
    public var builtIns: [any ShuffleAlgorithm] = []

    /// Same story as `AlgorithmRegistry.scriptLoader` — the JS-loading logic lives in
    /// `ScriptingKit`, which `AlgorithmKit` can't depend on without inverting the module graph.
    public var scriptLoader: (() -> [any ShuffleAlgorithm])?

    public init() {}

    public func discover() {
        shuffles = builtIns + (scriptLoader?() ?? [])
    }

    public func shuffle(id: ShuffleID) -> (any ShuffleAlgorithm)? {
        shuffles.first { $0.id == id }
    }
}
