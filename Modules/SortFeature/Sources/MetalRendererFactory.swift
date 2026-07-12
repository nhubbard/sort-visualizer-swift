import Metal
import VisualizationKit

/// The single place that maps a `VisualizerID` to its concrete Metal renderer — every built-in
/// `Visualizer` has one as of the wedge/chord batch (`MetalTriangleRenderer`/
/// `MetalDisparityChordsRenderer`), so `makeRenderer` returning `nil` only happens for an unknown
/// ID (never a current, registered one) — `MetalRendererView` still handles that case
/// defensively rather than force-unwrapping.
@MainActor
enum MetalRendererFactory {
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
        case "colorcircle": MetalTriangleRenderer<ColorCircleMetalLayout>(device: device, sampleCount: sampleCount)
        case "disparitycircle": MetalTriangleRenderer<DisparityCircleMetalLayout>(device: device, sampleCount: sampleCount)
        case "spiral": MetalTriangleRenderer<SpiralMetalLayout>(device: device, sampleCount: sampleCount)
        case "disparitychords": MetalDisparityChordsRenderer(device: device, sampleCount: sampleCount)
        default: nil
        }
    }
}
