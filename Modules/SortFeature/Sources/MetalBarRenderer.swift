import Foundation
import Metal
import MetalKit
import SortEngineKit

/// The GPU half of the incremental-update hypothesis: a persistent `MTLBuffer` of per-bar
/// instance data (`BarInstance`, layout-matched to `BarRenderer.metal`'s struct of the same
/// name), written incrementally — only the touched indices' slots, via direct pointer writes —
/// then drawn with exactly one instanced draw call per frame regardless of array size. The GPU
/// redraws every bar every frame no matter what (there's no partial-redraw concept for a GPU draw
/// call) — the win here is entirely that the CPU-side *write* is incremental, and that
/// GPU-instanced rectangle rendering is cheap enough per-instance that redrawing all of them every
/// frame stops being the bottleneck at all.
///
/// Works in pixel space throughout (not points): `MTKView`'s drawable is always sized in real
/// backing-store pixels, and the render encoder's implicit viewport matches that, so the vertex
/// shader's NDC conversion has to agree — `reset`/`apply` take points + a scale factor (matching
/// `IncrementalBarRenderer`'s shared contract) and convert internally.
@MainActor
final class MetalBarRenderer: NSObject, MetalIncrementalRenderer {
    struct BarInstance {
        var origin: SIMD2<Float>
        var size: SIMD2<Float>
        var color: SIMD4<Float>
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var instanceBuffer: MTLBuffer?
    private var count = 0
    private var lastCanvasSize: CGSize = .zero
    private var lastScale: CGFloat = 1
    /// Pixel-space canvas size — `lastCanvasSize (points) * lastScale`, recomputed on every
    /// `reset`. All bar geometry and the shader's viewport uniform work in this space directly.
    private var pixelSize: CGSize = .zero

    private static let defaultColor = SIMD4<Float>(0.82, 0.82, 0.86, 1)
    private static let primaryColor = SIMD4<Float>(0.95, 0.38, 0.38, 1)
    private static let secondaryColor = SIMD4<Float>(0.38, 0.58, 0.95, 1)

    /// `nil` if this device can't build the pipeline at all (no Metal support, or — it shouldn't
    /// happen given `BarRenderer.metal` ships in this same target, but defensively — the default
    /// library is missing the expected functions). Callers should fall back to a different
    /// backend rather than force-unwrap.
    ///
    /// `sampleCount` defaults to `1` (no MSAA) so existing tests driving `encodeDraw` against a
    /// plain, non-multisampled offscreen texture keep working unchanged — a render pipeline's
    /// `rasterSampleCount` must exactly match whatever render pass it's encoded into, or Metal
    /// fails validation. `MetalRendererView` is the only caller that passes a real value, matching
    /// whatever it set `MTKView.sampleCount` to.
    init?(device: MTLDevice, sampleCount: Int = 1) {
        guard let queue = device.makeCommandQueue() else { return nil }
        // `device.makeDefaultLibrary()` (no bundle argument) looks for `default.metallib` in
        // `Bundle.main` — the HOST APP's bundle, not the caller's own. `BarRenderer.metal`
        // compiles into `SortFeature.framework`'s own bundle, not the app's, so that overload
        // always returned `nil` here — silently, with no crash, which is exactly why nothing ever
        // drew: this whole initializer returned `nil`, and `MetalRendererView.makeUIView` fell
        // back to a bare, undelegated `MTKView()`. `makeDefaultLibrary(bundle:)` with THIS type's
        // own bundle is the fix — it looks in `SortFeature.framework` instead.
        guard
            let library = try? device.makeDefaultLibrary(bundle: Bundle(for: MetalBarRenderer.self)),
            let vertexFunction = library.makeFunction(name: "bar_vertex"),
            let fragmentFunction = library.makeFunction(name: "bar_fragment")
        else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.rasterSampleCount = sampleCount

        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }

        self.device = device
        self.commandQueue = queue
        self.pipelineState = pipelineState
        super.init()
    }

    func reset(
        values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>],
        canvasSize: CGSize, scale: CGFloat
    ) {
        lastCanvasSize = canvasSize
        lastScale = scale
        pixelSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
        count = values.count

        guard count > 0, pixelSize.width > 0, pixelSize.height > 0 else {
            instanceBuffer = nil
            return
        }
        guard
            let buffer = device.makeBuffer(
                length: MemoryLayout<BarInstance>.stride * count, options: .storageModeShared)
        else {
            instanceBuffer = nil
            return
        }
        instanceBuffer = buffer

        for index in values.indices {
            writeBar(index: index, values: values, valueRange: valueRange, markers: markers)
        }
    }

    func apply(_ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]) {
        guard instanceBuffer != nil, values.count == count else { return }

        guard let touched = operation.touchedIndices else {
            // `.unmark`/`.unmarkAll` — could affect any index; only a full repaint is correct.
            // `lastCanvasSize`/`lastScale` (not `pixelSize` — that's already the derived product
            // of the two, and can't be un-multiplied back into them) are exactly what the
            // previous `reset` call was given, so this reproduces it unchanged.
            reset(values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize, scale: lastScale)
            return
        }
        guard !touched.isEmpty else { return }

        for index in touched where values.indices.contains(index) {
            writeBar(index: index, values: values, valueRange: valueRange, markers: markers)
        }
    }

    private func writeBar(index: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]) {
        guard let instanceBuffer, count > 0 else { return }
        let barWidth = Float(pixelSize.width / Double(count))
        let spanLength = Double(valueRange.upperBound - valueRange.lowerBound)
        let normalizedHeight = spanLength > 0
            ? Double(values[index] - valueRange.lowerBound) / spanLength
            : 1.0
        let height = Float(pixelSize.height * normalizedHeight)
        // Top-left origin, bars anchored at the bottom — matches `BarGraphVisualizer` exactly
        // (see `BarRenderer.metal`'s vertex shader for how this point space maps to Metal's own
        // +Y-up NDC).
        let originY = Float(pixelSize.height) - height

        let bar = BarInstance(
            origin: SIMD2(Float(index) * barWidth, originY),
            size: SIMD2(barWidth, height),
            color: color(forIndex: index, in: markers)
        )
        instanceBuffer.contents()
            .advanced(by: index * MemoryLayout<BarInstance>.stride)
            .storeBytes(of: bar, as: BarInstance.self)
    }

    private func color(forIndex index: Int, in markers: [Int: Set<Int>]) -> SIMD4<Float> {
        let indexMarkers = markers[index] ?? []
        if indexMarkers.contains(Marker.primary) { return Self.primaryColor }
        if indexMarkers.contains(Marker.secondary) { return Self.secondaryColor }
        return Self.defaultColor
    }

    /// Fired from `mtkView(_:drawableSizeWillChange:)` below with the drawable's real pixel size
    /// — the authoritative "you now have somewhere real to render" signal, since
    /// `MetalRendererView.updateUIView` can run before `MTKView` has ever been laid out (drawable
    /// size still `.zero` at that point) with no guarantee SwiftUI calls it again once real
    /// layout happens. Relying on `updateUIView`'s own polling alone left the buffer permanently
    /// `nil` in exactly that case — nothing else drew on screen because nothing had ever `reset`.
    var onDrawableSizeChange: ((CGSize) -> Void)?

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated {
            onDrawableSizeChange?(size)
        }
    }

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            guard
                let drawable = view.currentDrawable,
                let passDescriptor = view.currentRenderPassDescriptor,
                let commandBuffer = commandQueue.makeCommandBuffer()
            else { return }

            encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    /// The actual draw-call encoding, pulled out of `draw(in:)` so it can be driven against an
    /// offscreen render target in a test — no `MTKView`/live drawable required — for empirical,
    /// pixel-readback diagnosis instead of guessing from GPU pipeline setup alone. Not `private`
    /// for exactly that reason: `@testable import` can see `internal`, never `private`.
    func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        guard
            let buffer = instanceBuffer, count > 0,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        var viewport = SIMD2<Float>(Float(pixelSize.width), Float(pixelSize.height))
        encoder.setVertexBytes(&viewport, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
        encoder.endEncoding()
    }
}
