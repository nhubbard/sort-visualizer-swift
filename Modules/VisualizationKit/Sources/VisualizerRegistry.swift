@MainActor
public final class VisualizerRegistry {
    public static let shared = VisualizerRegistry()

    public private(set) var visualizers: [any Visualizer] = []

    /// Every `Visualizer` is a compiled-in `BuiltInVisualizers` conformance (§2A.3) — no runtime
    /// script discovery, no manifest format. `VisualizationKit` has no visibility into
    /// `BuiltInVisualizers` (that dependency edge runs the other way), so whoever composes the app
    /// populates this before calling `discover()` — same pattern as `AlgorithmRegistry.builtIns`.
    public var builtIns: [any Visualizer] = []

    public init() {}

    public func discover() {
        visualizers = builtIns
    }

    public func visualizer(id: VisualizerID) -> (any Visualizer)? {
        visualizers.first { $0.id == id }
    }
}
