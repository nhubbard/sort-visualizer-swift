import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

/// GPU-buffer layout, matched exactly to `PolygonRenderer.metal`'s `LineInstance` struct.
struct MetalLineInstance {
    var start: SIMD2<Float>
    var end: SIMD2<Float>
    var thickness: Float
    var color: SIMD4<Float>
}

/// Bespoke, non-generic — like `MetalBarRenderer`, not `MetalShapeRenderer<Layout>`/
/// `MetalTriangleRenderer<Layout>` — because `DisparityChordsVisualizer` is the only line-based
/// visualizer; a generic `MetalLineLayout` protocol would have exactly one conformance, all cost
/// and no reuse. Ports `DisparityChordsVisualizer.draw(_:)`'s math directly: one chord per index,
/// from that index's own position-angle point to its value-angle point, both on a fixed circle —
/// no neighbor dependency (unlike the wedge visualizers), so `apply` is a plain 1:1 index-to-slot
/// write, same shape as `MetalBarRenderer.writeBar`.
@MainActor
final class MetalDisparityChordsRenderer: NSObject, MetalIncrementalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var instanceBuffer: MTLBuffer?
    private var count = 0
    private var lastCanvasSize: CGSize = .zero
    private var lastScale: CGFloat = 1
    private var pixelSize: CGSize = .zero

    private let colorTransitions = MetalColorTransitionTracker()
    private let startTransitions = MetalTransitionTracker<SIMD2<Float>>()
    private let endTransitions = MetalTransitionTracker<SIMD2<Float>>()
    /// See `MetalBarRenderer.lastFrameTimestamp`'s doc comment.
    private var lastFrameTimestamp: CFTimeInterval?

    private static let lineWidth: Double = 1

    /// `nil` under the same conditions `MetalBarRenderer.init?` can be — see that initializer's
    /// own doc comment for why `makeDefaultLibrary(bundle:)` is required. `sampleCount` defaults
    /// to `1` (no MSAA) for the same reason `MetalBarRenderer`'s does — see `MetalSampleCount`.
    init?(device: MTLDevice, sampleCount: Int = 1) {
        guard let queue = device.makeCommandQueue() else { return nil }
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: MetalDisparityChordsRenderer.self)) else {
            return nil
        }
        guard
            let vertexFunction = library.makeFunction(name: "line_vertex"),
            let fragmentFunction = library.makeFunction(name: "line_fragment")
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
        colorTransitions.reset()
        startTransitions.reset()
        endTransitions.reset()

        guard count > 0, pixelSize.width > 0, pixelSize.height > 0 else {
            instanceBuffer = nil
            return
        }
        guard
            let buffer = device.makeBuffer(
                length: MemoryLayout<MetalLineInstance>.stride * count, options: .storageModeShared)
        else {
            instanceBuffer = nil
            return
        }
        instanceBuffer = buffer

        for index in values.indices {
            writeChord(index: index, values: values, valueRange: valueRange, markers: markers)
        }
    }

    func apply(_ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]) {
        guard instanceBuffer != nil, values.count == count else { return }

        guard let touched = operation.touchedIndices else {
            reset(values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize, scale: lastScale)
            return
        }
        guard !touched.isEmpty else { return }

        for index in touched where values.indices.contains(index) {
            writeChord(index: index, values: values, valueRange: valueRange, markers: markers)
        }
    }

    /// Same `angle(k) = π*(2k/n - 0.5)` `DisparityChordsVisualizer.angle(_:count:)` uses, generalized
    /// to a `Double` input since the chord's far endpoint plugs a raw *value* into this formula,
    /// not just an index.
    private static func angle(_ position: Double, count: Int) -> Double {
        .pi * (2.0 * position / Double(count) - 0.5)
    }

    private func writeChord(index: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]) {
        guard let instanceBuffer, count > 0 else { return }
        let value = values[index]
        let center = SIMD2<Double>(pixelSize.width / 2, pixelSize.height / 2)
        let radius = min(pixelSize.width, pixelSize.height) / 2.5
        let fromAngle = Self.angle(Double(index), count: count)
        let toAngle = Self.angle(Double(value), count: count)

        let rawStart = SIMD2(Float(center.x + radius * cos(fromAngle)), Float(center.y + radius * sin(fromAngle)))
        let rawEnd = SIMD2(Float(center.x + radius * cos(toAngle)), Float(center.y + radius * sin(toAngle)))
        let chord = MetalLineInstance(
            start: startTransitions.valueToWrite(forSlot: index, target: rawStart),
            end: endTransitions.valueToWrite(forSlot: index, target: rawEnd),
            thickness: Float(Self.lineWidth * lastScale),
            color: colorTransitions.valueToWrite(
                forSlot: index, target: color(forIndex: index, value: value, valueRange: valueRange, markers: markers))
        )
        instanceBuffer.contents()
            .advanced(by: index * MemoryLayout<MetalLineInstance>.stride)
            .storeBytes(of: chord, as: MetalLineInstance.self)
    }

    private func color(
        forIndex index: Int, value: Int, valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
    ) -> SIMD4<Float> {
        MetalShapeColor.marker(forIndex: index, in: markers)
            ?? MetalShapeColor.hueRamp(MetalShapeColor.normalized(value: value, in: valueRange))
    }

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

            let now = CACurrentMediaTime()
            let elapsed = lastFrameTimestamp.map { now - $0 } ?? 0
            lastFrameTimestamp = now
            advanceTransitions(elapsed: elapsed)

            encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
            commandBuffer.present(drawable)
            commandBuffer.commit()

            // See `MetalBarRenderer.draw(in:)`'s own comment on why this uses MetalKit's own
            // capped internal display link instead of manually re-arming `setNeedsDisplay()`.
            if colorTransitions.isActive || startTransitions.isActive || endTransitions.isActive {
                if view.isPaused { view.isPaused = false }
            } else if !view.isPaused {
                view.isPaused = true
            }
        }
    }

    /// See `MetalBarRenderer.advanceTransitions`'s doc comment.
    func advanceTransitions(elapsed: TimeInterval) {
        guard let instanceBuffer, count > 0 else { return }
        let colorChanges = colorTransitions.advance(elapsed: elapsed)
        let startChanges = startTransitions.advance(elapsed: elapsed)
        let endChanges = endTransitions.advance(elapsed: elapsed)
        let changedSlots = Set(colorChanges.keys).union(startChanges.keys).union(endChanges.keys)
        guard !changedSlots.isEmpty else { return }
        let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalLineInstance.self)
        for slot in changedSlots {
            if let color = colorTransitions.displayed(forSlot: slot) { pointer[slot].color = color }
            if let start = startTransitions.displayed(forSlot: slot) { pointer[slot].start = start }
            if let end = endTransitions.displayed(forSlot: slot) { pointer[slot].end = end }
        }
    }

    /// Test seam, same shape as `MetalBarRenderer.encodeDraw`.
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

    /// Test seam, same shape as `MetalShapeRenderer.debugInstances`.
    func debugInstances() -> [MetalLineInstance] {
        guard let instanceBuffer else { return [] }
        let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalLineInstance.self)
        return (0..<count).map { pointer[$0] }
    }
}
