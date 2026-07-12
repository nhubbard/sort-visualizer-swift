import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

enum MetalShapeKind {
    case rect
    case ellipse
}

/// GPU-buffer layout, matched exactly to `ShapeRenderer.metal`'s `ShapeInstance` struct.
struct MetalShapeInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
}

/// Per-visualizer geometry contract for `MetalShapeRenderer<Self>` — mirrors that `Visualizer`'s
/// own `draw(_:) -> [DrawCommand]` math almost line for line, just computing one GPU instance at a
/// time instead of appending to an array, and in POINTS (matching every `Visualizer`'s own
/// `context.canvasSize` convention) rather than pixels — `MetalShapeRenderer` converts to pixel
/// space generically, the same way `MetalBarRenderer` does, so ported math doesn't have to.
///
/// Separates "which array index feeds this instance" (`arrayIndex(forSlot:)`) from "which
/// instance(s) does this array index touch" (`slots(forIndex:)`) because most visualizers have a
/// 1:1 index-to-instance mapping (the defaults below), but two don't: `PixelMeshMetalLayout`
/// resamples `values.count` indices across a differently-sized grid of cells, and
/// `HoopStackMetalLayout` reverses draw order so index 0 paints last (on top) — both still need
/// true O(touched) incremental `apply`, not a full `reset`, which requires knowing the exact
/// instance slot(s) a changed index maps to instead of assuming slot == index.
///
/// Deliberately NOT `@MainActor` — every requirement is a pure value computation with no Metal/UI
/// state, called from `MetalShapeRenderer`'s already-`@MainActor` methods either way, and leaving
/// it unisolated lets `MetalShapeLayoutTests` call these directly, synchronously, with no actor
/// hop needed to test math that never touches actor-isolated state in the first place.
protocol MetalShapeLayout {
    static var shapeKind: MetalShapeKind { get }

    /// Total GPU instance count for a given array length. Default: one instance per index.
    static func instanceCount(for count: Int) -> Int

    /// Which array index feeds a given instance slot's value/markers — the inverse of
    /// `slots(forIndex:count:)`. Default: identity.
    static func arrayIndex(forSlot slot: Int, count: Int) -> Int

    /// Which instance slot(s) must be repainted when a given array index changes. Default:
    /// identity (one slot per index).
    static func slots(forIndex index: Int, count: Int) -> [Int]

    /// `arrayIndex` is always `Self.arrayIndex(forSlot: slot, count: count)`, precomputed by the
    /// caller so conformances don't each have to call it again themselves.
    static func instance(
        atSlot slot: Int, arrayIndex: Int, values: [Int], valueRange: ClosedRange<Int>,
        markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
    ) -> MetalShapeInstance
}

extension MetalShapeLayout {
    static func instanceCount(for count: Int) -> Int { count }
    static func arrayIndex(forSlot slot: Int, count: Int) -> Int { slot }
    static func slots(forIndex index: Int, count: Int) -> [Int] { [index] }
}

/// The generic sibling of `MetalBarRenderer` for every OTHER incrementally-portable visualizer —
/// identical GPU plumbing (persistent instance buffer, one instanced draw call, incremental
/// per-touched-index writes), parametrized by `Layout` for the one thing that actually differs
/// per visualizer: how to turn an array index into on-screen geometry. `MetalBarRenderer` itself
/// stays a separate, untouched type rather than becoming `MetalShapeRenderer<BarGraphLayout>` —
/// it's already shipped and user-verified; no reason to risk it for a cosmetic unification.
@MainActor
final class MetalShapeRenderer<Layout: MetalShapeLayout>: NSObject, MetalIncrementalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var instanceBuffer: MTLBuffer?
    private var slotCount = 0
    private var arrayCount = 0
    private var lastCanvasSize: CGSize = .zero
    private var lastScale: CGFloat = 1
    private var pixelSize: CGSize = .zero

    private let colorTransitions = MetalColorTransitionTracker()
    private let originTransitions = MetalTransitionTracker<SIMD2<Float>>()
    private let sizeTransitions = MetalTransitionTracker<SIMD2<Float>>()
    /// See `MetalIncrementalRenderer.reduceFlashingEnabled`'s doc comment.
    var reduceFlashingEnabled = false {
        didSet {
            colorTransitions.isEnabled = reduceFlashingEnabled
            originTransitions.isEnabled = reduceFlashingEnabled
            sizeTransitions.isEnabled = reduceFlashingEnabled
        }
    }
    /// See `MetalBarRenderer.lastFrameTimestamp`'s doc comment.
    private var lastFrameTimestamp: CFTimeInterval?

    /// `nil` under the same conditions `MetalBarRenderer.init?` can be — see that initializer's
    /// own doc comment for why `makeDefaultLibrary(bundle:)` (this type's own framework bundle),
    /// not the bundle-less overload, is required here too. `sampleCount` — see
    /// `MetalSampleCount`'s own doc comment for why this defaults to `1` (no MSAA) rather than
    /// hardcoding real antialiasing in here directly.
    init?(device: MTLDevice, sampleCount: Int = 1) {
        guard let queue = device.makeCommandQueue() else { return nil }
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)) else { return nil }
        let fragmentFunctionName = Layout.shapeKind == .rect ? "rect_fragment" : "ellipse_fragment"
        guard
            let vertexFunction = library.makeFunction(name: "shape_vertex"),
            let fragmentFunction = library.makeFunction(name: fragmentFunctionName)
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
        arrayCount = values.count
        slotCount = Layout.instanceCount(for: arrayCount)
        colorTransitions.reset()
        originTransitions.reset()
        sizeTransitions.reset()

        guard slotCount > 0, pixelSize.width > 0, pixelSize.height > 0 else {
            instanceBuffer = nil
            return
        }
        guard
            let buffer = device.makeBuffer(
                length: MemoryLayout<MetalShapeInstance>.stride * slotCount, options: .storageModeShared)
        else {
            instanceBuffer = nil
            return
        }
        instanceBuffer = buffer

        for slot in 0..<slotCount {
            writeInstance(slot: slot, values: values, valueRange: valueRange, markers: markers)
        }
    }

    func apply(_ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]) {
        guard instanceBuffer != nil, values.count == arrayCount else { return }

        guard let touched = operation.touchedIndices else {
            reset(values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize, scale: lastScale)
            return
        }
        guard !touched.isEmpty else { return }

        for index in touched where values.indices.contains(index) {
            for slot in Layout.slots(forIndex: index, count: arrayCount) where (0..<slotCount).contains(slot) {
                writeInstance(slot: slot, values: values, valueRange: valueRange, markers: markers)
            }
        }
    }

    private func writeInstance(slot: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]) {
        guard let instanceBuffer, arrayCount > 0 else { return }
        let index = Layout.arrayIndex(forSlot: slot, count: arrayCount)
        guard values.indices.contains(index) else { return }

        var instance = Layout.instance(
            atSlot: slot, arrayIndex: index, values: values, valueRange: valueRange,
            markers: markers, canvasSize: lastCanvasSize, count: arrayCount
        )
        // Layouts compute in points, matching every `Visualizer.draw`'s own convention — scale to
        // pixels here, once, generically, same as `MetalBarRenderer.writeBar` does inline.
        instance.origin = originTransitions.valueToWrite(forSlot: slot, target: instance.origin * Float(lastScale))
        instance.size = sizeTransitions.valueToWrite(forSlot: slot, target: instance.size * Float(lastScale))
        instance.color = colorTransitions.valueToWrite(forSlot: slot, target: instance.color)

        instanceBuffer.contents()
            .advanced(by: slot * MemoryLayout<MetalShapeInstance>.stride)
            .storeBytes(of: instance, as: MetalShapeInstance.self)
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
            if colorTransitions.isActive || originTransitions.isActive || sizeTransitions.isActive {
                if view.isPaused { view.isPaused = false }
            } else if !view.isPaused {
                view.isPaused = true
            }
        }
    }

    /// See `MetalBarRenderer.advanceTransitions`'s doc comment.
    func advanceTransitions(elapsed: TimeInterval) {
        guard let instanceBuffer, slotCount > 0 else { return }
        let colorChanges = colorTransitions.advance(elapsed: elapsed)
        let originChanges = originTransitions.advance(elapsed: elapsed)
        let sizeChanges = sizeTransitions.advance(elapsed: elapsed)
        let changedSlots = Set(colorChanges.keys).union(originChanges.keys).union(sizeChanges.keys)
        guard !changedSlots.isEmpty else { return }
        let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalShapeInstance.self)
        for slot in changedSlots {
            if let color = colorTransitions.displayed(forSlot: slot) { pointer[slot].color = color }
            if let origin = originTransitions.displayed(forSlot: slot) { pointer[slot].origin = origin }
            if let size = sizeTransitions.displayed(forSlot: slot) { pointer[slot].size = size }
        }
    }

    /// Test seam: a snapshot of the current instance buffer's raw contents, in slot order — lets a
    /// test check exactly which slots hold stale/wrong data directly, without rendering to a
    /// texture and inferring values back from pixel colors.
    func debugInstances() -> [MetalShapeInstance] {
        guard let instanceBuffer else { return [] }
        let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalShapeInstance.self)
        return (0..<slotCount).map { pointer[$0] }
    }

    /// Same test seam as `MetalBarRenderer.encodeDraw` — lets a test drive this against an
    /// offscreen texture instead of a live `MTKView`.
    func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        guard
            let buffer = instanceBuffer, slotCount > 0,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        var viewport = SIMD2<Float>(Float(pixelSize.width), Float(pixelSize.height))
        encoder.setVertexBytes(&viewport, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: slotCount)
        encoder.endEncoding()
    }
}
