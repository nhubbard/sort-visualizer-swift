import Testing

@testable import SortFeature

/// Regression coverage for a real bug this project hit: `AnimatedFloat2`'s raw (unpadded) size
/// used to be smaller than its own alignment-padded stride, and Swift's nested-struct field-offset
/// computation uses raw `size` while MSL/C always uses the alignment-padded `sizeof` — so a field
/// following an `AnimatedFloat2` (like `MetalLineInstance.thickness`) could land at a different
/// byte offset in Swift than the shader expected, silently corrupting whichever fields came after
/// it. Fixed via an explicit padding field making `size == stride`. `AnimatedColorSource`/
/// `AnimatedMarkerColor` (the color-resolution-on-GPU structs) were designed from the start to be
/// all 4-byte-aligned scalars specifically to avoid this class of bug entirely — these tests assert
/// that invariant directly for every animated-field type, plus the resulting stride of every
/// GPU-buffer struct that embeds them, so a future field reordering/addition that reintroduces a
/// similar gap fails loudly here instead of as a rendering bug only visible via pixel readback (see
/// `MetalPolygonRendererTests.linePipelineRendersAlongItsOwnMidpoint`, which is what actually
/// caught the original bug).
@Suite
struct MetalAnimatedFieldLayoutTests {
  @Test
  func animatedFloat2HasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedFloat2>.size == MemoryLayout<AnimatedFloat2>.stride)
    #expect(MemoryLayout<AnimatedFloat2>.stride == 24)
  }

  @Test
  func animatedColorSourceHasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedColorSource>.size == MemoryLayout<AnimatedColorSource>.stride)
    #expect(MemoryLayout<AnimatedColorSource>.stride == 20)
  }

  @Test
  func animatedMarkerColorHasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedMarkerColor>.size == MemoryLayout<AnimatedMarkerColor>.stride)
    #expect(MemoryLayout<AnimatedMarkerColor>.stride == 12)
  }

  @Test
  func metalAnimationUniformsStride() {
    #expect(MemoryLayout<MetalAnimationUniforms>.stride == 80)
  }

  @Test
  func barInstanceStride() {
    #expect(MemoryLayout<MetalBarRenderer.BarInstance>.stride == 64)
  }

  @Test
  func shapeGPUInstanceStride() {
    #expect(MemoryLayout<MetalShapeGPUInstance>.stride == 72)
  }

  @Test
  func triangleGPUInstanceStride() {
    #expect(MemoryLayout<MetalTriangleGPUInstance>.stride == 96)
  }

  /// The struct that actually exposed the original bug: `thickness` (a plain, small-alignment
  /// scalar) sits between two `AnimatedFloat2` fields and the color field — exactly the
  /// arrangement where the Swift/MSL packing divergence manifested when color was still
  /// `AnimatedFloat4`. Now that color is `AnimatedColorSource` (no internal padding of its own),
  /// this struct's layout is unambiguous by construction, but the assertion stays as a permanent
  /// tripwire.
  @Test
  func lineInstanceStride() {
    #expect(MemoryLayout<MetalLineInstance>.stride == 72)
  }

  @Test
  func hanoiOriginHasNoInternalPadding() {
    #expect(MemoryLayout<HanoiOrigin>.size == MemoryLayout<HanoiOrigin>.stride)
    #expect(MemoryLayout<HanoiOrigin>.stride == 32)
  }

  @Test
  func hanoiInstanceStride() {
    #expect(MemoryLayout<HanoiInstance>.stride == 64)
  }
}
