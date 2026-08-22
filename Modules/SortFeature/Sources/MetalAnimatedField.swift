import Foundation

/// Per-frame animation uniform, replacing the lone `viewportSize` every vertex shader used to
/// take at buffer index 1 — layout-matched to `AnimatedField.h`'s `AnimationUniforms`. Filling
/// this struct and one `setVertexBytes` call is the ONLY per-frame CPU work related to animation
/// left in any renderer once easing moves to the shader: the vertex function resolves every
/// instance's animated fields itself, in parallel, using `currentTime` — no CPU sweep over
/// "active" instances required regardless of how many are mid-transition.
///
/// `primaryColor`/`secondaryColor`/`neutralColor`/`useHueRamp` exist so color RESOLUTION (not just
/// easing) can move into the shader too: `MetalShapeColor.hueRamp`/`.marker` used to run on the
/// CPU once per touched slot per operation; now every vertex shader computes the same pure
/// function itself via `AnimatedField.h`'s `resolveColorSource`, fed by these renderer-wide
/// constants (which DO change live with light/dark mode, hence living in the per-frame uniform
/// rather than being baked into the pipeline at construction time) plus each instance's own raw
/// `(value, marker)` ingredients. `useHueRamp` is a per-`MetalShapeLayout` choice (`ScatterPlot`/
/// `WaveDots` use flat `neutralColor` instead — see `MetalShapeLayout.usesHueRamp`); every other
/// renderer always hue-ramps and just passes `1`.
struct MetalAnimationUniforms {
  var viewportSize: SIMD2<Float>
  var currentTime: Float
  var transitionDuration: Float
  var useHueRamp: Float
  var primaryColor: SIMD4<Float>
  var secondaryColor: SIMD4<Float>
  var neutralColor: SIMD4<Float>
  /// The array size and value-range bounds a geometry formula needs but no single instance owns
  /// (every slot in one draw call shares the same `count`/`valueRange`) — added for
  /// `MetalBarRenderer`'s GPU-side geometry (`bar_vertex` now computes `barWidth`/`height` itself
  /// from an eased raw `value` instead of the CPU precomputing an already-positioned rect), and
  /// reusable by future `MetalShapeLayout`/`MetalTriangleLayout` ports needing the same two
  /// per-frame constants. `arrayCount` is `Float` (not `Int`) purely so the shader can divide by
  /// it directly with no int-to-float conversion at the call site; this app's own audited
  /// `maxArraySize` (256) is nowhere near `Float`'s 2^24 exact-integer ceiling.
  var arrayCount: Float
  var valueRangeLowerBound: Float
  var valueRangeSpan: Float
  /// Points-to-pixels scale factor — needed so a geometry formula's FIXED point-based constants
  /// (e.g. `ScatterPlotMetalLayout`'s 6pt dot diameter) render at the correct pixel size on any
  /// display scale, now that those formulas run in the shader against pixel-space `viewportSize`
  /// rather than being computed once in points on the CPU and scaled up afterward (what
  /// `MetalShapeRenderer.writeInstance` used to do via `target.origin * Float(lastScale)`).
  var scale: Float
  /// Selects which `MetalShapeGeometryKind` case `shape_vertex` uses for this draw call — fixed
  /// per `Layout` type, read once from `MetalShapeLayout.geometryKind` and passed through
  /// unchanged every frame. `-1` for every renderer that isn't `MetalShapeRenderer` (Bar, Triangle,
  /// DisparityChords, Hanoi don't read this field at all).
  var geometryKind: Int32
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
/// both languages, so no following field can ever land at different offsets.
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

/// An unresolved COLOR SOURCE — raw `(value, marker)` ingredients at each end of a fade, rather
/// than precomputed RGBA. `value` (normalized 0...1) feeds a hue-ramp; `marker` (`0` = none, `1` =
/// primary, `2` = secondary, matching `Marker.primary`/`Marker.secondary`'s raw values exactly) is
/// checked first and overrides `value` entirely when non-zero. Every field is a plain 4-byte-
/// aligned scalar — unlike `AnimatedFloat2`, this struct's raw size is already a multiple of its
/// own alignment (20 bytes, align 4), so it carries none of that padding risk.
///
/// Written by `MetalColorSourceTracker.valueToWrite`, resolved every frame by `AnimatedField.h`'s
/// `resolveAnimatedColorSource` — see `MetalColorSourceTracker`'s own doc comment for why
/// retargeting continues from the PREVIOUS TARGET's ingredients rather than a live-resolved
/// blended color (a deliberate, disclosed simplification, not an oversight).
struct AnimatedColorSource {
  var fromValue: Float
  var fromMarker: Int32
  var toValue: Float
  var toMarker: Int32
  var startTime: Float
}

/// `MetalBarRenderer`'s own simpler color source — Bar never hue-ramps (always one of
/// `primaryColor`/`secondaryColor`/`neutralColor`-as-default), so there's no `value` ingredient at
/// all, just the marker. Same 4-byte-scalar-only shape as `AnimatedColorSource`, same no-padding-
/// risk reasoning.
struct AnimatedMarkerColor {
  var fromMarker: Int32
  var toMarker: Int32
  var startTime: Float
}

/// The scalar counterpart to `AnimatedFloat2` — an unresolved `(from, to, startTime)` triple for a
/// single `Float`, not a `SIMD2`. First user: `MetalBarRenderer`'s GPU-geometry port, which only
/// ever needs to ease the bar's raw underlying VALUE (not a precomputed screen position) — `
/// bar_vertex` derives `origin`/`size` itself from the eased value plus `MetalAnimationUniforms`'s
/// `arrayCount`/`valueRangeLowerBound`/`valueRangeSpan`. All 3 fields are already 4-byte-aligned
/// scalars, so — like `AnimatedColorSource`/`AnimatedMarkerColor` — this carries none of
/// `AnimatedFloat2`'s SIMD-alignment padding risk; no explicit `_padding` field needed.
struct AnimatedFloat {
  var from: Float
  var to: Float
  var startTime: Float
}
