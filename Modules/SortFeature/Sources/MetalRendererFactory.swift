import Metal
import VisualizationKit

/// The single place that knows which `VisualizerID`s have a working incremental Metal path.
/// `SortView.canvas(for:)` checks `supportedVisualizerIDs` (no device needed) to decide whether to
/// mount `MetalRendererView` at all, falling back to `VisualizationCanvas` (Immediate) for anything
/// not listed here — the .metal/.polygon/.line visualizers (`ColorCircle`, `DisparityCircle`,
/// `Spiral`, `DisparityChords`) don't have a `MetalShapeLayout` yet.
@MainActor
enum MetalRendererFactory {
    static let supportedVisualizerIDs: Set<VisualizerID> = [
        VisualizerID(rawValue: "bargraph"),
        VisualizerID(rawValue: "disparitybargraph"),
        VisualizerID(rawValue: "pixelmesh"),
        VisualizerID(rawValue: "rainbow"),
        VisualizerID(rawValue: "sinewave"),
        VisualizerID(rawValue: "disparitydots"),
        VisualizerID(rawValue: "hoopstack"),
        VisualizerID(rawValue: "scatterplot"),
        VisualizerID(rawValue: "spiraldots"),
        VisualizerID(rawValue: "wavedots"),
    ]

    /// `sampleCount` must match whatever the caller set `MTKView.sampleCount` to — a render
    /// pipeline's `rasterSampleCount` has to agree exactly with the render pass it's encoded into.
    static func makeRenderer(
        for visualizerID: VisualizerID, device: MTLDevice, sampleCount: Int
    ) -> (any MetalIncrementalRenderer)? {
        switch visualizerID.rawValue {
        case "bargraph": MetalBarRenderer(device: device, sampleCount: sampleCount)
        case "disparitybargraph": MetalShapeRenderer<DisparityBarGraphMetalLayout>(device: device, sampleCount: sampleCount)
        case "pixelmesh": MetalShapeRenderer<PixelMeshMetalLayout>(device: device, sampleCount: sampleCount)
        case "rainbow": MetalShapeRenderer<RainbowMetalLayout>(device: device, sampleCount: sampleCount)
        case "sinewave": MetalShapeRenderer<SineWaveMetalLayout>(device: device, sampleCount: sampleCount)
        case "disparitydots": MetalShapeRenderer<DisparityDotsMetalLayout>(device: device, sampleCount: sampleCount)
        case "hoopstack": MetalShapeRenderer<HoopStackMetalLayout>(device: device, sampleCount: sampleCount)
        case "scatterplot": MetalShapeRenderer<ScatterPlotMetalLayout>(device: device, sampleCount: sampleCount)
        case "spiraldots": MetalShapeRenderer<SpiralDotsMetalLayout>(device: device, sampleCount: sampleCount)
        case "wavedots": MetalShapeRenderer<WaveDotsMetalLayout>(device: device, sampleCount: sampleCount)
        default: nil
        }
    }
}
