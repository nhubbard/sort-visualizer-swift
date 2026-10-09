import Foundation
import Metal
import MetalKit
import SettingsKit
import SortEngineKit
import VisualizationKit

private struct ImageTileGPUInstance {
  var sourceSlot: UInt32
  var marker: UInt32
}

private struct ImageTileUniforms {
  var viewportSize: SIMD2<Float>
  var contentOrigin: SIMD2<Float>
  var contentSize: SIMD2<Float>
  var columns: UInt32
  var rows: UInt32
  var edgeFraction: Float
}

/// One textured quad per grid cell, encoded as a single instanced draw. The CPU updates only
/// operation-touched cells; the shader derives both destination and source rectangles.
@MainActor
final class MetalImageTileRenderer: NSObject, MetalIncrementalRenderer {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLRenderPipelineState
  private let texture: any MTLTexture
  private let imageAspectRatio: Double
  private var instanceBuffer: MTLBuffer?
  private var layout = ImageTileLayout(count: 0, aspectRatio: 1)
  private var pixelSize: CGSize = .zero
  private var valueRange: ClosedRange<Int> = 0...1
  private var canvasSize: CGSize = .zero
  private var scale: CGFloat = 1

  var onDrawableSizeChange: ((CGSize) -> Void)?

  init?(device: MTLDevice, sampleCount: Int = 1, sourceImage: CGImage? = nil) {
    guard let queue = device.makeCommandQueue(),
          let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)),
          let vertex = library.makeFunction(name: "image_tile_vertex"),
          let fragment = library.makeFunction(name: "image_tile_fragment") else { return nil }
    let image = sourceImage ?? CustomImageStore.shared.image
    guard let loadedTexture = try? MTKTextureLoader(device: device).newTexture(
      cgImage: image, options: [.origin: MTKTextureLoader.Origin.topLeft,
                                .SRGB: true]) else { return nil }

    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = vertex
    descriptor.fragmentFunction = fragment
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.rasterSampleCount = sampleCount
    guard let pipeline = try? device.makeRenderPipelineState(descriptor: descriptor) else {
      return nil
    }
    self.device = device
    commandQueue = queue
    pipelineState = pipeline
    texture = loadedTexture
    imageAspectRatio = Double(image.width) / Double(image.height)
    super.init()
  }

  func reset(
    values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>],
    canvasSize: CGSize, scale: CGFloat
  ) {
    self.canvasSize = canvasSize
    self.scale = scale
    self.valueRange = valueRange
    pixelSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    layout = ImageTileLayout(count: values.count, aspectRatio: imageAspectRatio)
    guard layout.cellCount > 0, pixelSize.width > 0, pixelSize.height > 0,
          let buffer = device.makeBuffer(
            length: MemoryLayout<ImageTileGPUInstance>.stride * layout.cellCount,
            options: .storageModeShared) else {
      instanceBuffer = nil
      return
    }
    instanceBuffer = buffer
    for slot in 0..<layout.cellCount {
      write(slot: slot, values: values, markers: markers)
    }
  }

  func apply(
    _ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    guard instanceBuffer != nil, values.count == layout.movingCount else { return }
    if self.valueRange != valueRange {
      reset(values: values, valueRange: valueRange, markers: markers,
            canvasSize: canvasSize, scale: scale)
      return
    }
    guard let touched = operation.touchedIndices else {
      reset(values: values, valueRange: valueRange, markers: markers,
            canvasSize: canvasSize, scale: scale)
      return
    }
    for slot in touched where (0..<layout.movingCount).contains(slot) {
      write(slot: slot, values: values, markers: markers)
    }
  }

  private func write(slot: Int, values: [Int], markers: [Int: Set<Int>]) {
    guard let instanceBuffer else { return }
    let markerSet = slot < layout.movingCount ? markers[slot] ?? [] : []
    let marker = markerSet.contains(Marker.primary) ? 1
      : markerSet.contains(Marker.secondary) ? 2 : 0
    let instance = ImageTileGPUInstance(
      sourceSlot: UInt32(layout.sourceSlot(
        forDestination: slot, values: values, valueRange: valueRange)),
      marker: UInt32(marker))
    instanceBuffer.contents()
      .advanced(by: slot * MemoryLayout<ImageTileGPUInstance>.stride)
      .storeBytes(of: instance, as: ImageTileGPUInstance.self)
  }

  nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    MainActor.assumeIsolated { onDrawableSizeChange?(size) }
  }

  nonisolated func draw(in view: MTKView) {
    MainActor.assumeIsolated {
      guard let drawable = view.currentDrawable,
            let pass = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer() else { return }
      encodeDraw(into: pass, commandBuffer: commandBuffer)
      commandBuffer.present(drawable)
      commandBuffer.commit()
    }
  }

  func encodeDraw(into pass: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
    guard let buffer = instanceBuffer, layout.cellCount > 0,
          let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
    let viewport = SIMD2(Float(pixelSize.width), Float(pixelSize.height))
    let imageAspect = Float(imageAspectRatio)
    let canvasAspect = viewport.x / max(1, viewport.y)
    let fittedSize = imageAspect > canvasAspect
      ? SIMD2(viewport.x, viewport.x / imageAspect)
      : SIMD2(viewport.y * imageAspect, viewport.y)
    let origin = (viewport - fittedSize) / 2
    let cellPixels = min(fittedSize.x / Float(layout.columns),
                         fittedSize.y / Float(layout.rows))
    var uniforms = ImageTileUniforms(
      viewportSize: viewport, contentOrigin: origin, contentSize: fittedSize,
      columns: UInt32(layout.columns), rows: UInt32(layout.rows),
      edgeFraction: cellPixels >= 6 ? min(0.12, 1.5 / cellPixels) : 0)
    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<ImageTileUniforms>.stride, index: 1)
    encoder.setFragmentTexture(texture, index: 0)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0,
                           vertexCount: 4, instanceCount: layout.cellCount)
    encoder.endEncoding()
  }

  func debugSourceSlots() -> [Int] {
    guard let instanceBuffer else { return [] }
    let values = instanceBuffer.contents().assumingMemoryBound(to: ImageTileGPUInstance.self)
    return (0..<layout.cellCount).map { Int(values[$0].sourceSlot) }
  }
}
