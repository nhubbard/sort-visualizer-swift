import Metal
import Testing

@testable import SortFeature

/// Pixel-readback coverage for `useHueRamp`'s actual GPU branch (`AnimatedField.h`'s
/// `resolveColorSource`) — `resolvedInstances(at:)`-based tests elsewhere only verify the Swift
/// CPU reference implementation agrees with itself; they can't catch a bug in the ported MSL code
/// (a flipped `useHueRamp > 0.5` comparison, a uniform never actually reaching the shader, etc.).
/// Same offscreen-texture + `getBytes` readback technique `MetalPolygonRendererTests` established
/// — the technique that caught the real `MetalLineInstance` struct-layout bug in the first place.
@Suite
struct MetalShapeColorResolutionPixelTests {
  @MainActor
  @Test
  func scatterPlotNeverHueRampsEvenAtAMaximalValue() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalShapeRenderer<ScatterPlotMetalLayout>(device: device))
    let width = 60
    let height = 60
    // A single element at its maximum value: if `useHueRamp` were incorrectly `true` here, this
    // would render a saturated magenta/pink (`hueRamp(1.0)`) instead of `MetalShapeColor.neutral`
    // (a light, unsaturated gray) — a maximally distinguishing case.
    renderer.reset(
      values: [10], valueRange: 0...10, markers: [:], canvasSize: CGSize(width: width, height: height),
      scale: 1)

    let instance = try #require(renderer.debugInstances().first)
    let centerX = Int((instance.origin.to.x + instance.size.to.x / 2).rounded())
    let centerY = Int((instance.origin.to.y + instance.size.to.y / 2).rounded())

    let pixel = try render(renderer, device: device, width: width, height: height, x: centerX, y: centerY)
    let neutral = MetalShapeColor.neutral
    #expect(
      isClose(pixel, neutral),
      "ScatterPlot must render its flat neutral default, not a hue-ramped color, even at the max value"
    )
    #expect(
      !isClose(pixel, expectedHueRampAtMax),
      "sanity: the neutral and hue-ramp-at-1.0 colors must actually differ, or this test proves nothing"
    )
  }

  @MainActor
  @Test
  func rainbowLayoutHueRampsAtAMaximalValueRatherThanStayingNeutral() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalShapeRenderer<RainbowMetalLayout>(device: device))
    let width = 60
    let height = 60
    renderer.reset(
      values: [10], valueRange: 0...10, markers: [:], canvasSize: CGSize(width: width, height: height),
      scale: 1)

    let instance = try #require(renderer.debugInstances().first)
    // `RainbowMetalLayout` is a `.rect` (bar) shape spanning the full canvas width and (at the max
    // value) the full height — sample well inside it rather than at its exact origin corner.
    let sampleX = Int((instance.origin.to.x + instance.size.to.x / 2).rounded())
    let sampleY = height / 2

    let pixel = try render(
      renderer, device: device, width: width, height: height, x: sampleX, y: sampleY)
    #expect(
      isClose(pixel, expectedHueRampAtMax),
      "Rainbow must hue-ramp at the max value, matching MetalShapeColor.hueRamp(1.0) exactly"
    )
    #expect(
      !isClose(pixel, MetalShapeColor.neutral),
      "sanity: must not have rendered the flat neutral default instead"
    )
  }

  /// `MetalShapeColor.hueRamp(1.0)` — the real production function, not a hand-recomputed
  /// constant, so this stays correct if that function's math ever legitimately changes.
  private var expectedHueRampAtMax: SIMD4<Float> { MetalShapeColor.hueRamp(1.0) }

  private func isClose(_ lhs: SIMD4<Float>, _ rhs: SIMD4<Float>, tolerance: Float = 0.02) -> Bool {
    let delta = lhs - rhs
    return abs(delta.x) < tolerance && abs(delta.y) < tolerance && abs(delta.z) < tolerance
  }

  @MainActor
  private func render(
    _ renderer: MetalShapeRenderer<some MetalShapeLayout>, device: MTLDevice, width: Int, height: Int,
    x: Int, y: Int
  ) throws -> SIMD4<Float> {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.renderTarget, .shaderRead]
    descriptor.storageMode = .shared
    let texture = try #require(device.makeTexture(descriptor: descriptor))

    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = texture
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    passDescriptor.colorAttachments[0].storeAction = .store

    let queue = try #require(device.makeCommandQueue())
    let commandBuffer = try #require(queue.makeCommandBuffer())
    renderer.encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    #expect(commandBuffer.error == nil)

    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
    texture.getBytes(
      &pixels, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

    let offset = y * bytesPerRow + x * 4
    // `.bgra8Unorm` — byte order is B, G, R, A.
    let blue = Float(pixels[offset]) / 255
    let green = Float(pixels[offset + 1]) / 255
    let red = Float(pixels[offset + 2]) / 255
    let alpha = Float(pixels[offset + 3]) / 255
    return SIMD4(red, green, blue, alpha)
  }
}
