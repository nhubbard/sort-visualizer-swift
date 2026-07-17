import Metal

/// Shared MSAA sample-count policy for every live (on-screen) Metal renderer — `MetalBarRenderer`/
/// `MetalShapeRenderer` both take an explicit `sampleCount` at init rather than hardcoding one,
/// because a render pipeline's `rasterSampleCount` must exactly match whatever render pass it's
/// ever encoded into (`MTKView.sampleCount` for the live path, or a plain non-multisampled
/// offscreen texture in tests) — a mismatch is a Metal validation failure, not a soft error. Tests
/// rely on both initializers defaulting to `1` (no MSAA) so their existing plain offscreen
/// textures keep working unchanged; only `MetalRendererView` opts into real antialiasing.
enum MetalSampleCount {
  /// Highest MSAA sample count `device` actually supports, smoothing the hard-pixelated edges
  /// `ShapeRenderer.metal`/`BarRenderer.metal`/`PolygonRenderer.metal` otherwise produce (none of
  /// them do their own fragment-shader edge falloff).
  ///
  /// Tried in descending order rather than assuming one fixed value: Apple GPUs universally
  /// guarantee 1x/4x (the Metal Feature Set tables' only REQUIRED counts), but 8x — and even 2x —
  /// are permitted-not-guaranteed, varying by GPU generation. Checking `supportsTextureSampleCount`
  /// live picks the actual best available on whatever device this runs on, rather than hardcoding
  /// today's hardware's ceiling and leaving future/other GPUs stuck below their own maximum.
  static func preferred(for device: MTLDevice) -> Int {
    for candidate in [8, 4, 2, 1] where device.supportsTextureSampleCount(candidate) {
      return candidate
    }
    return 1
  }
}
