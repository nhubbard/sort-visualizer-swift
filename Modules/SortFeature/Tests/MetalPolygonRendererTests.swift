import Metal
import Testing

@testable import SortFeature

/// Permanent regression coverage for the two new shape kinds (`Modules/SortFeature/Sources/PolygonRenderer.metal`)
/// — same offscreen-texture + `getBytes` readback technique `MetalShapeRendererBufferConsistencyTests`
/// established for rects/ellipses, applied to triangles and lines. Samples the ACTUAL computed
/// triangle's own centroid (from `debugInstances()`, not hand-derived trigonometry) as the
/// "must be painted" point — a non-degenerate triangle's centroid is always strictly inside itself,
/// so this works regardless of exactly which angles/radii a given layout computes, and a canvas
/// corner far outside every wedge/chord's radius as the "must stay unpainted" point.
@Suite
struct MetalPolygonRendererTests {
  @MainActor
  @Test
  func trianglePipelineRendersAtItsOwnCentroid() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalTriangleRenderer<ColorCircleMetalLayout>(device: device))
    let width = 200
    let height = 200
    renderer.reset(
      values: [1, 2, 3, 4], valueRange: 1...4, markers: [:],
      canvasSize: CGSize(width: width, height: height), scale: 1
    )

    // Fresh off `reset()` — every field's `from == to` (a first-ever paint shows immediately, no
    // fade in flight yet), so resolving at any `currentTime` gives the actual painted point.
    // `resolvedInstances(at:)` derives p0/p1/p2 via `resolveTriangleGeometry` — there's no raw
    // point left on the buffer itself to read (see `MetalTriangleGPUInstance`'s doc comment).
    let wedge0 = try #require(renderer.resolvedInstances(at: 0).first)
    let centroidX = Int((wedge0.p0.x + wedge0.p1.x + wedge0.p2.x) / 3)
    let centroidY = Int((wedge0.p0.y + wedge0.p1.y + wedge0.p2.y) / 3)

    let pixels = try render(renderer, device: device, width: width, height: height)
    let bytesPerRow = width * 4
    let centroidAlpha = alpha(pixels, bytesPerRow: bytesPerRow, x: centroidX, y: centroidY)
    // Top-left corner: distance from center (100,100) is ~134pt, well outside the ~72.7pt
    // wedge radius (`min(w,h)/2.75`) — guaranteed outside every wedge regardless of layout.
    let cornerAlpha = alpha(pixels, bytesPerRow: bytesPerRow, x: 5, y: 5)

    print("DIAGNOSTIC triangle centroidAlpha=\(centroidAlpha) cornerAlpha=\(cornerAlpha)")
    #expect(centroidAlpha > 0, "a triangle's own centroid must be inside itself")
    #expect(cornerAlpha == 0, "far outside every wedge's radius must stay unpainted")
  }

  @MainActor
  @Test
  func linePipelineRendersAlongItsOwnMidpoint() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalDisparityChordsRenderer(device: device))
    // scale: 4 (not 1) — `thickness = lineWidth(1pt) * scale`, so a 1px-wide line at scale 1
    // covers so few pixel CENTERS (GPU rasterization only shades a fragment whose pixel center
    // falls inside the primitive) that an exact-midpoint sample can miss it by sub-pixel
    // rounding alone. A thicker line removes that flakiness without changing what's tested.
    let width = 800
    let height = 800
    // Index 0's chord goes from angle(0, count) to angle(values[0], count) — avoid
    // `values[0] == count` specifically: `angle(count, count) - angle(0, count) == 2π`
    // exactly, making that one chord a zero-length point by pure periodic coincidence, not a
    // bug (confirmed by first trying `[4, 1, 3, 2]`, which hits exactly this case at count=4).
    renderer.reset(
      values: [2, 4, 1, 3], valueRange: 1...4, markers: [:],
      canvasSize: CGSize(width: 200, height: 200), scale: 4
    )

    // See the triangle test's own comment on why resolving at any `currentTime` is safe straight
    // off a fresh reset — `resolvedInstances(at:)` derives start/end via `resolveChordGeometry`,
    // there's no raw point left on the buffer itself to read (see `MetalLineInstance`'s doc comment).
    let chord0 = try #require(renderer.resolvedInstances(at: 0).first)
    let midX = Int(((chord0.start.x + chord0.end.x) / 2).rounded())
    let midY = Int(((chord0.start.y + chord0.end.y) / 2).rounded())

    let pixels = try render(renderer, device: device, width: width, height: height)
    let bytesPerRow = width * 4
    let midAlpha = alpha(pixels, bytesPerRow: bytesPerRow, x: midX, y: midY)
    let cornerAlpha = alpha(pixels, bytesPerRow: bytesPerRow, x: 5, y: 5)

    print("DIAGNOSTIC line midAlpha=\(midAlpha) cornerAlpha=\(cornerAlpha)")
    #expect(midAlpha > 0, "a chord's own midpoint must lie on the chord")
    #expect(cornerAlpha == 0, "far outside every chord's radius must stay unpainted")
  }

  @MainActor
  private func render(
    _ renderer: some OffscreenEncodable, device: MTLDevice, width: Int, height: Int
  ) throws -> [UInt8] {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false
    )
    descriptor.usage = [.renderTarget, .shaderRead]
    descriptor.storageMode = .shared
    let texture = try #require(device.makeTexture(descriptor: descriptor))

    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = texture
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].clearColor = MTLClearColor(
      red: 0, green: 0, blue: 0, alpha: 0)
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
    return pixels
  }

  private func alpha(_ pixels: [UInt8], bytesPerRow: Int, x: Int, y: Int) -> UInt8 {
    pixels[y * bytesPerRow + x * 4 + 3]
  }
}

/// Minimal shared shape for the two renderer types under test here — both already expose
/// `encodeDraw(into:commandBuffer:)` as a test seam; this just lets `render(_:...)` above take
/// either one without duplicating its body.
@MainActor
protocol OffscreenEncodable {
  func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
}
extension MetalTriangleRenderer: OffscreenEncodable {}
extension MetalDisparityChordsRenderer: OffscreenEncodable {}
