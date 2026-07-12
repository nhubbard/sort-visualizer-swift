import CoreGraphics

/// A `Visualizer` never sees *how* the algorithm works — only `ReplayEngine`'s current,
/// already-computed frame (values + markers + aux arrays). Direct port of ArrayV's own
/// separation: `Visual.drawVisual` never touches `Sort`/`Reads`/`Writes`.
public struct VisualizationContext: Sendable {
    /// `ReplayEngine.frame`, unwrapped to raw ints.
    public let values: [Int]
    /// For normalizing height/hue/radius.
    public let valueRange: ClosedRange<Int>
    /// index -> marker IDs active on it (inverse of `ReplayEngine.BarState.markers`).
    public let markers: [Int: Set<Int>]
    /// `AuxHandle.rawValue` -> contents, drawn as extra strips.
    public let auxArrays: [Int: [Int]]
    public let canvasSize: CGSize
    /// `TapeHeader.visualSeed`, for deterministic per-run color choices.
    public let colorSeed: UInt64

    public init(
        values: [Int],
        valueRange: ClosedRange<Int>,
        markers: [Int: Set<Int>],
        auxArrays: [Int: [Int]],
        canvasSize: CGSize,
        colorSeed: UInt64
    ) {
        self.values = values
        self.valueRange = valueRange
        self.markers = markers
        self.auxArrays = auxArrays
        self.canvasSize = canvasSize
        self.colorSeed = colorSeed
    }
}
