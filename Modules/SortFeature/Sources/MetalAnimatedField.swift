import Foundation

/// Per-frame animation uniform, replacing the lone `viewportSize` every vertex shader used to
/// take at buffer index 1 — layout-matched to `AnimatedField.h`'s `AnimationUniforms`. Filling
/// this struct and one `setVertexBytes` call is the ONLY per-frame CPU work related to animation
/// left in any renderer once easing moves to the shader: the vertex function resolves every
/// instance's animated fields itself, in parallel, using `currentTime` — no CPU sweep over
/// "active" instances required regardless of how many are mid-transition.
struct MetalAnimationUniforms {
  var viewportSize: SIMD2<Float>
  var currentTime: Float
  var transitionDuration: Float
}

/// An unresolved animated 2D field (a position, a size, a triangle/line point) — `from`/`to`/
/// `startTime` instead of an already-interpolated value. Written once per touched slot per
/// `SortOperation.apply` by `MetalPositionTransitionTracker.valueToWrite`; resolved every frame by
/// the vertex shader via `AnimatedField.h`'s `resolveAnimated2`, not by any CPU-side sweep.
/// Layout-matched to `AnimatedField.h`'s `AnimatedFloat2` struct.
///
/// `_padding` is NOT cosmetic: `from`(8)+`to`(8)+`startTime`(4) is 20 raw bytes, but this struct's
/// own alignment (8, from its `SIMD2<Float>` members) pads its STRIDE to 24 — and Swift and MSL
/// disagree on whether a smaller-alignment field immediately following an `AnimatedFloat2` (e.g.
/// `MetalLineInstance.thickness`) may pack into that 4-byte gap: Swift's field-offset computation
/// uses a nested struct's raw `size` (20), while MSL/C always uses the alignment-padded `sizeof`
/// (24). That divergence is a REAL bug this project hit (`MetalLineInstance`'s `thickness`/`color`
/// landing at different byte offsets in the GPU buffer than the shader expected, silently
/// corrupting geometry) — not a hypothetical one. Explicit padding makes raw size equal stride in
/// both languages, so no following field can ever land at different offsets — the same fix is
/// applied to `AnimatedFloat4` below for the identical reason.
struct AnimatedFloat2 {
  var from: SIMD2<Float>
  var to: SIMD2<Float>
  var startTime: Float
  // Not `private`: a `private` stored property would make the synthesized memberwise
  // initializer `private` too (usable only within this file), breaking every other file's
  // `AnimatedFloat2(from:to:startTime:)` call. The leading underscore alone signals "don't set
  // this" to a reader without narrowing the init's actual access level.
  var _padding: Float = 0
}

/// The color counterpart to `AnimatedFloat2` — written by `MetalColorTransitionTracker
/// .valueToWrite`, resolved by `AnimatedField.h`'s `resolveAnimated4`. Layout-matched to
/// `AnimatedField.h`'s `AnimatedFloat4`. See `AnimatedFloat2`'s own doc comment for why the
/// explicit padding (here, 12 bytes: `from`(16)+`to`(16)+`startTime`(4) = 36 raw vs. this struct's
/// 16-byte-aligned 48-byte stride) is load-bearing, not cosmetic.
struct AnimatedFloat4 {
  var from: SIMD4<Float>
  var to: SIMD4<Float>
  var startTime: Float
  // See `AnimatedFloat2._padding`'s own comment on why these aren't `private`.
  var _padding0: Float = 0
  var _padding1: Float = 0
  var _padding2: Float = 0
}
