import Foundation
import Metal
import MetalKit
import SortEngineKit

/// GPU-buffer layout, matched exactly to `PolygonRenderer.metal`'s `TriangleInstance` struct.
struct MetalTriangleInstance {
    var p0: SIMD2<Float>
    var p1: SIMD2<Float>
    var p2: SIMD2<Float>
    var color: SIMD4<Float>
}

/// Per-visualizer geometry contract for `MetalTriangleRenderer<Self>` — the triangle-wedge sibling
/// of `MetalShapeLayout` (`MetalShapeRenderer.swift`), same design for the same reason: mirrors
/// that `Visualizer`'s own `draw(_:) -> [DrawCommand]` math almost line for line, in points (this
/// renderer converts to pixels generically), with the same `arrayIndex(forSlot:)`/
/// `slots(forIndex:)` split for visualizers whose geometry depends on a NEIGHBOR's value, not just
/// their own — `DisparityCircleMetalLayout`/`SpiralMetalLayout`'s wedge `i` uses both point `i-1`
/// and point `i`, so touching index `i` must repaint wedges `i` AND `i+1`
/// (`Modules/SortFeature/Sources/MetalPolygonVisualizerLayouts.swift`).
///
/// Deliberately NOT `@MainActor`, same reasoning as `MetalShapeLayout`.
protocol MetalTriangleLayout {
    static func instanceCount(for count: Int) -> Int
    static func arrayIndex(forSlot slot: Int, count: Int) -> Int
    static func slots(forIndex index: Int, count: Int) -> [Int]

    static func instance(
        atSlot slot: Int, arrayIndex: Int, values: [Int], valueRange: ClosedRange<Int>,
        markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
    ) -> MetalTriangleInstance
}

extension MetalTriangleLayout {
    static func instanceCount(for count: Int) -> Int { count }
    static func arrayIndex(forSlot slot: Int, count: Int) -> Int { slot }
    static func slots(forIndex index: Int, count: Int) -> [Int] { [index] }
}

/// The triangle-wedge sibling of `MetalShapeRenderer<Layout>` — identical GPU plumbing (persistent
/// instance buffer, one instanced draw call, incremental per-touched-index writes), just with 3
/// explicit points per instance instead of a bounding box, and `.triangle` primitives (3
/// vertices/instance, no shared strip corner) instead of `.triangleStrip`.
@MainActor
final class MetalTriangleRenderer<Layout: MetalTriangleLayout>: NSObject, MetalIncrementalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var instanceBuffer: MTLBuffer?
    private var slotCount = 0
    private var arrayCount = 0
    private var lastCanvasSize: CGSize = .zero
    private var lastScale: CGFloat = 1
    private var pixelSize: CGSize = .zero

    /// `nil` under the same conditions `MetalBarRenderer.init?` can be — see that initializer's
    /// own doc comment for why `makeDefaultLibrary(bundle:)` is required. `sampleCount` defaults to
    /// `1` (no MSAA) for the same reason `MetalShapeRenderer`'s does — see `MetalSampleCount`.
    init?(device: MTLDevice, sampleCount: Int = 1) {
        guard let queue = device.makeCommandQueue() else { return nil }
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)) else { return nil }
        guard
            let vertexFunction = library.makeFunction(name: "triangle_vertex"),
            let fragmentFunction = library.makeFunction(name: "triangle_fragment")
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

        guard slotCount > 0, pixelSize.width > 0, pixelSize.height > 0 else {
            instanceBuffer = nil
            return
        }
        guard
            let buffer = device.makeBuffer(
                length: MemoryLayout<MetalTriangleInstance>.stride * slotCount, options: .storageModeShared)
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
        // pixels here, once, generically, same as `MetalShapeRenderer.writeInstance` does.
        instance.p0 *= Float(lastScale)
        instance.p1 *= Float(lastScale)
        instance.p2 *= Float(lastScale)

        instanceBuffer.contents()
            .advanced(by: slot * MemoryLayout<MetalTriangleInstance>.stride)
            .storeBytes(of: instance, as: MetalTriangleInstance.self)
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

            encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    /// Test seam, same shape as `MetalShapeRenderer.debugInstances`.
    func debugInstances() -> [MetalTriangleInstance] {
        guard let instanceBuffer else { return [] }
        let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalTriangleInstance.self)
        return (0..<slotCount).map { pointer[$0] }
    }

    /// Test seam, same shape as `MetalShapeRenderer.encodeDraw` — drives this against an offscreen
    /// texture instead of a live `MTKView`.
    func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        guard
            let buffer = instanceBuffer, slotCount > 0,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        var viewport = SIMD2<Float>(Float(pixelSize.width), Float(pixelSize.height))
        encoder.setVertexBytes(&viewport, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: slotCount)
        encoder.endEncoding()
    }
}
