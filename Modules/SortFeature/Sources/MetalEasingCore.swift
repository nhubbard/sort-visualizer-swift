import Foundation

/// Shared by `MetalPositionTransitionTracker`, `MetalColorSourceTracker`, and
/// `MetalMarkerColorTracker` — kept as a plain constant/function rather than inherited from a
/// common (generic or protocol) base, so none of them ever touch generic dispatch machinery. Also
/// ported byte-for-byte into `AnimatedField.h` (`easeInOutCubic`) for the GPU-side resolution these
/// trackers no longer perform themselves every frame.
let transitionDuration: TimeInterval = 0.12

/// Ease-in-out (cubic) rather than linear — see `AnimatedField.h`'s ported copy for the full
/// rationale (kept there since that's where it actually runs every frame now). This CPU-side copy
/// is only ever called at *retarget* time (when a slot's target changes mid-fade, to compute
/// "wherever it's currently, visually sitting" as the new fade's starting point) — never once per
/// frame — so keeping it here alongside the trackers that call it, rather than trying to share a
/// single implementation across the CPU/GPU boundary, is simpler than it might look at first
/// glance despite the literal duplication with `AnimatedField.h`.
func easeInOutCubic(_ t: Float) -> Float {
  guard t >= 0.5 else { return 4 * t * t * t }
  let f = -2 * t + 2
  return 1 - f * f * f / 2
}

/// CPU mirror of `AnimatedField.h`'s `resolveAnimated2` — resolves a raw `(from, to, startTime)`
/// triple already sitting in a GPU buffer to its displayed value at `now`, independent of any
/// tracker's internal state. Used only by renderers' `resolvedInstances(at:)` test seams (a
/// convenience for asserting against pinned, deterministic probe times instead of racing a live
/// clock) — never on a per-frame production path, which is the shader's job.
func resolveAnimated2(_ field: AnimatedFloat2, at now: Float) -> SIMD2<Float> {
  let t = min(max((now - field.startTime) / Float(transitionDuration), 0), 1)
  let eased = easeInOutCubic(t)
  return field.from + (field.to - field.from) * SIMD2<Float>(repeating: eased)
}
