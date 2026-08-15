import Testing

@testable import SortFeature

/// Regression coverage for a real bug this project hit: `AnimatedFloat2`/`AnimatedFloat4`'s raw
/// (unpadded) size used to be smaller than their own alignment-padded stride, and Swift's
/// nested-struct field-offset computation uses raw `size` while MSL/C always uses the
/// alignment-padded `sizeof` — so a field following an `AnimatedFloat2`/`AnimatedFloat4` (like
/// `MetalLineInstance.thickness`) could land at a different byte offset in Swift than the shader
/// expected, silently corrupting whichever fields came after it. Fixed via explicit padding
/// fields making `size == stride` for both types — these tests assert that invariant directly,
/// plus the resulting stride of every GPU-buffer struct that embeds them, so a future field
/// reordering/addition that reintroduces the gap fails loudly here instead of as a rendering bug
/// only visible via pixel readback (see `MetalPolygonRendererTests
/// .linePipelineRendersAlongItsOwnMidpoint`, which is what actually caught this the first time).
@Suite
struct MetalAnimatedFieldLayoutTests {
  @Test
  func animatedFloat2HasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedFloat2>.size == MemoryLayout<AnimatedFloat2>.stride)
    #expect(MemoryLayout<AnimatedFloat2>.stride == 24)
  }

  @Test
  func animatedFloat4HasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedFloat4>.size == MemoryLayout<AnimatedFloat4>.stride)
    #expect(MemoryLayout<AnimatedFloat4>.stride == 48)
  }

  @Test
  func metalAnimationUniformsStride() {
    #expect(MemoryLayout<MetalAnimationUniforms>.stride == 16)
  }

  @Test
  func barInstanceStride() {
    #expect(MemoryLayout<MetalBarRenderer.BarInstance>.stride == 96)
  }

  @Test
  func shapeGPUInstanceStride() {
    #expect(MemoryLayout<MetalShapeGPUInstance>.stride == 96)
  }

  @Test
  func triangleGPUInstanceStride() {
    #expect(MemoryLayout<MetalTriangleGPUInstance>.stride == 128)
  }

  /// The struct that actually exposed the bug: `thickness` (a plain, small-alignment scalar)
  /// sits between two `AnimatedFloat2` fields and one `AnimatedFloat4` field — exactly the
  /// arrangement where the Swift/MSL packing divergence manifested.
  @Test
  func lineInstanceStride() {
    #expect(MemoryLayout<MetalLineInstance>.stride == 112)
  }

  @Test
  func hanoiOriginHasNoInternalPadding() {
    #expect(MemoryLayout<HanoiOrigin>.size == MemoryLayout<HanoiOrigin>.stride)
    #expect(MemoryLayout<HanoiOrigin>.stride == 32)
  }

  @Test
  func hanoiInstanceStride() {
    #expect(MemoryLayout<HanoiInstance>.stride == 96)
  }
}
