import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

/// GPU-buffer layout, matched exactly to `PolygonRenderer.metal`'s `LineInstance` struct —
/// `start`/`end`/`color` are unresolved `(from, to, startTime)` triples, resolved every frame by
/// `line_vertex` itself (`resolveAnimated2`/`resolveAnimated4`, `AnimatedField.h`); `thickness`
/// stays a plain, unanimated scalar — it's a fixed derived value (`lineWidth * scale`), never fed
/// through a transition tracker.
struct MetalLineInstance {
  var start: AnimatedFloat2
  var end: AnimatedFloat2
  var thickness: Float
  var color: AnimatedColorSource
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

  private let colorTransitions = MetalColorSourceTracker()
  private let startTransitions = MetalPositionTransitionTracker()
  private let endTransitions = MetalPositionTransitionTracker()
  /// See `MetalBarRenderer.timeEpoch`/`now()`'s doc comments.
  private var timeEpoch: CFTimeInterval = CACurrentMediaTime()
  private func now() -> Float { Float(CACurrentMediaTime() - timeEpoch) }

  private static let lineWidth: Double = 1

  /// `nil` under the same conditions `MetalBarRenderer.init?` can be — see that initializer's
  /// own doc comment for why `makeDefaultLibrary(bundle:)` is required. `sampleCount` defaults
  /// to `1` (no MSAA) for the same reason `MetalBarRenderer`'s does — see `MetalSampleCount`.
  init?(device: MTLDevice, sampleCount: Int = 1) {
    guard let queue = device.makeCommandQueue() else { return nil }
    guard
      let library = try? device.makeDefaultLibrary(
        bundle: Bundle(for: MetalDisparityChordsRenderer.self))
    else {
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

    guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else {
      return nil
    }

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
    timeEpoch = CACurrentMediaTime()

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

  func apply(
    _ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    guard instanceBuffer != nil, values.count == count else { return }

    guard let touched = operation.touchedIndices else {
      reset(
        values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize,
        scale: lastScale)
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

  private func writeChord(
    index: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    guard let instanceBuffer, count > 0 else { return }
    let value = values[index]
    let center = SIMD2<Double>(pixelSize.width / 2, pixelSize.height / 2)
    let radius = min(pixelSize.width, pixelSize.height) / 2.5
    let fromAngle = Self.angle(Double(index), count: count)
    let toAngle = Self.angle(Double(value), count: count)

    let rawStart = SIMD2(
      Float(center.x + radius * cos(fromAngle)), Float(center.y + radius * sin(fromAngle)))
    let rawEnd = SIMD2(
      Float(center.x + radius * cos(toAngle)), Float(center.y + radius * sin(toAngle)))
    let n = now()
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    let chord = MetalLineInstance(
      start: startTransitions.valueToWrite(forSlot: index, target: rawStart, now: n),
      end: endTransitions.valueToWrite(forSlot: index, target: rawEnd, now: n),
      thickness: Float(Self.lineWidth * lastScale),
      color: colorTransitions.valueToWrite(
        forSlot: index, value: Float(normalized),
        marker: MetalShapeColor.markerKind(forIndex: index, in: markers), now: n)
    )
    instanceBuffer.contents()
      .advanced(by: index * MemoryLayout<MetalLineInstance>.stride)
      .storeBytes(of: chord, as: MetalLineInstance.self)
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

      // See `MetalBarRenderer.draw(in:)`'s own comment on why this uses MetalKit's own
      // capped internal display link instead of manually re-arming `setNeedsDisplay()`.
      let n = now()
      if colorTransitions.isActive(now: n) || startTransitions.isActive(now: n)
        || endTransitions.isActive(now: n) {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  /// Test seam, same shape as `MetalBarRenderer.encodeDraw`.
  func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
    encodeDraw(into: passDescriptor, commandBuffer: commandBuffer, currentTime: now())
  }

  /// Test-only overload — see `MetalBarRenderer`'s own overload of the same name for why.
  func encodeDraw(
    into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer,
    currentTime: Float
  ) {
    guard
      let buffer = instanceBuffer, count > 0,
      let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
    else { return }

    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    // `useHueRamp: 1` unconditionally — `DisparityChordsVisualizer` always hue-ramps.
    var uniforms = MetalAnimationUniforms(
      viewportSize: SIMD2(Float(pixelSize.width), Float(pixelSize.height)),
      currentTime: currentTime, transitionDuration: Float(transitionDuration), useHueRamp: 1,
      primaryColor: MetalShapeColor.primary, secondaryColor: MetalShapeColor.secondary,
      neutralColor: MetalShapeColor.neutral)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalAnimationUniforms>.size, index: 1)
    encoder.drawPrimitives(
      type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
    encoder.endEncoding()
  }

  /// Test seam: the RAW current instance buffer contents — see `MetalShapeRenderer
  /// .debugInstances`'s doc comment.
  func debugInstances() -> [MetalLineInstance] {
    guard let instanceBuffer else { return [] }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalLineInstance.self)
    return (0..<count).map { pointer[$0] }
  }

  /// Test seam: resolved displayed values (`start`/`end`/`color`) at a pinned `currentTime` —
  /// `thickness` passes through unchanged since it's never animated. See `MetalShapeRenderer
  /// .resolvedInstances(at:)`'s doc comment.
  struct ResolvedLineInstance {
    var start: SIMD2<Float>
    var end: SIMD2<Float>
    var thickness: Float
    var color: SIMD4<Float>
  }

  func resolvedInstances(at currentTime: Float) -> [ResolvedLineInstance] {
    debugInstances().map {
      ResolvedLineInstance(
        start: resolveAnimated2($0.start, at: currentTime),
        end: resolveAnimated2($0.end, at: currentTime),
        thickness: $0.thickness,
        color: resolveAnimatedColorSource(
          $0.color, at: currentTime, useHueRamp: true, primaryColor: MetalShapeColor.primary,
          secondaryColor: MetalShapeColor.secondary, neutralColor: MetalShapeColor.neutral))
    }
  }
}
