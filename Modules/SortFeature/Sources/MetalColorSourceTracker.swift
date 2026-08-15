import Foundation

/// CPU reference implementation of `AnimatedField.h`'s `resolveColorSource` — used ONLY by test
/// seams (`resolvedInstances(at:)` on every renderer), never on a per-frame production path.
/// Deliberately reuses `MetalShapeColor.hueRamp` (not a second hand-ported HSV implementation) so
/// there's exactly one Swift-side source of truth for the hue-ramp math, matching what the MSL
/// port in `AnimatedField.h` must independently agree with — shader-parity tests are what actually
/// verify the MSL side, not this function.
func resolveColorSource(
  value: Float, marker: Int32, useHueRamp: Bool, primaryColor: SIMD4<Float>,
  secondaryColor: SIMD4<Float>, neutralColor: SIMD4<Float>
) -> SIMD4<Float> {
  if marker == 1 { return primaryColor }
  if marker == 2 { return secondaryColor }
  return useHueRamp ? MetalShapeColor.hueRamp(Double(value)) : neutralColor
}

/// CPU reference implementation of `AnimatedField.h`'s `resolveAnimatedColorSource` — see
/// `resolveColorSource`'s own doc comment on why this exists only for test seams.
func resolveAnimatedColorSource(
  _ source: AnimatedColorSource, at now: Float, useHueRamp: Bool, primaryColor: SIMD4<Float>,
  secondaryColor: SIMD4<Float>, neutralColor: SIMD4<Float>
) -> SIMD4<Float> {
  let fromColor = resolveColorSource(
    value: source.fromValue, marker: source.fromMarker, useHueRamp: useHueRamp,
    primaryColor: primaryColor, secondaryColor: secondaryColor, neutralColor: neutralColor)
  let toColor = resolveColorSource(
    value: source.toValue, marker: source.toMarker, useHueRamp: useHueRamp,
    primaryColor: primaryColor, secondaryColor: secondaryColor, neutralColor: neutralColor)
  let t = min(max((now - source.startTime) / Float(transitionDuration), 0), 1)
  let eased = easeInOutCubic(t)
  return fromColor + (toColor - fromColor) * SIMD4<Float>(repeating: eased)
}

/// CPU reference implementation of `AnimatedField.h`'s `resolveAnimatedMarkerColor` — see
/// `resolveColorSource`'s own doc comment on why this exists only for test seams.
func resolveAnimatedMarkerColor(
  _ source: AnimatedMarkerColor, at now: Float, primaryColor: SIMD4<Float>,
  secondaryColor: SIMD4<Float>, neutralColor: SIMD4<Float>
) -> SIMD4<Float> {
  let fromColor = source.fromMarker == 1 ? primaryColor : (source.fromMarker == 2 ? secondaryColor : neutralColor)
  let toColor = source.toMarker == 1 ? primaryColor : (source.toMarker == 2 ? secondaryColor : neutralColor)
  let t = min(max((now - source.startTime) / Float(transitionDuration), 0), 1)
  let eased = easeInOutCubic(t)
  return fromColor + (toColor - fromColor) * SIMD4<Float>(repeating: eased)
}

/// Tracks each GPU instance slot's animated color as an unresolved `(value, marker)` pair at each
/// end of a fade (`AnimatedColorSource`) instead of a resolved RGBA — the vertex shader computes
/// the actual hue-ramp/marker-override color itself every frame via `AnimatedField.h`'s
/// `resolveAnimatedColorSource`, so NO CPU call to `MetalShapeColor.hueRamp`/`.marker` happens on
/// this path at all anymore, not even the once-per-touched-operation call the earlier resolved-RGBA
/// tracker design still needed.
///
/// **Deliberate behavior simplification, disclosed not hidden**: `MetalPositionTransitionTracker`/
/// the old color tracker continue a mid-fade retarget from wherever the value is CURRENTLY,
/// VISUALLY sitting (a live blend) — computed via a CPU-side reference implementation of the
/// easing math. That's not available here: this tracker only ever stores raw `(value, marker)`
/// ingredients, never a resolved color, and an arbitrary blended RGBA generally can't be expressed
/// back as valid ingredients (there's no "value" whose hue-ramp equals an arbitrary in-between
/// color). So a retarget here continues from the PREVIOUS TARGET's ingredients instead — visually,
/// a color that's mid-fade toward A and gets retargeted toward B before finishing will restart
/// fading from A (already fully-formed) toward B, rather than from whatever blend of "old color"
/// and A it was mid-transition through. This trades a small amount of continuity fidelity (only
/// visible when retargets land faster than `transitionDuration`, i.e. fast/Fixed-Duration
/// playback) for eliminating essentially all CPU-side color computation — the whole point of this
/// migration. Position/geometry easing is UNCHANGED by this — only color's continuation contract
/// is different.
@MainActor
final class MetalColorSourceTracker {
  private struct Entry {
    var fromValue: Float
    var fromMarker: Int32
    var toValue: Float
    var toMarker: Int32
    var startTime: Float
  }

  private var entries: [Int: Entry] = [:]
  /// The latest instant at which any tracked entry could still be mid-fade — an O(1) substitute
  /// for scanning every entry every frame. Only ever grows (extended at retarget time to
  /// `now + transitionDuration`), so once `now` passes it, NOTHING can still be fading — `isActive`
  /// reporting `false` is exact, not approximate.
  private var settleDeadline: Float?

  func reset() {
    entries.removeAll()
    settleDeadline = nil
  }

  /// Called every time a renderer would otherwise compute+write a resolved color directly into
  /// its GPU buffer. Returns the `(fromValue, fromMarker, toValue, toMarker, startTime)` triple to
  /// write THIS call — the shader resolves it into an actual displayed color every subsequent
  /// frame on its own.
  func valueToWrite(forSlot slot: Int, value: Float, marker: Int32, now: Float) -> AnimatedColorSource {
    guard var entry = entries[slot] else {
      // First-ever value for this slot — nothing to fade from, so show it immediately: `from ==
      // to` resolves to that same color at any `t`, no special-casing needed on the GPU side.
      entries[slot] = Entry(fromValue: value, fromMarker: marker, toValue: value, toMarker: marker, startTime: now)
      return AnimatedColorSource(fromValue: value, fromMarker: marker, toValue: value, toMarker: marker, startTime: now)
    }
    if entry.toValue != value || entry.toMarker != marker {
      // See this class's own doc comment: `from` becomes the PREVIOUS TARGET's ingredients, not
      // a live-resolved blend.
      entry = Entry(
        fromValue: entry.toValue, fromMarker: entry.toMarker, toValue: value, toMarker: marker,
        startTime: now)
      entries[slot] = entry
      settleDeadline = max(settleDeadline ?? -.infinity, now + Float(transitionDuration))
    }
    return AnimatedColorSource(
      fromValue: entry.fromValue, fromMarker: entry.fromMarker, toValue: entry.toValue,
      toMarker: entry.toMarker, startTime: entry.startTime)
  }

  /// O(1) — whether ANY slot could still be mid-fade at `now`, the caller's cue to keep re-arming
  /// redraws.
  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }
}

/// `MetalBarRenderer`'s own simpler tracker — same shape as `MetalColorSourceTracker` but for
/// `AnimatedMarkerColor` (no `value` ingredient, since Bar never hue-ramps). See
/// `MetalColorSourceTracker`'s own doc comment for the identical retarget-continuity trade-off.
@MainActor
final class MetalMarkerColorTracker {
  private struct Entry {
    var fromMarker: Int32
    var toMarker: Int32
    var startTime: Float
  }

  private var entries: [Int: Entry] = [:]
  private var settleDeadline: Float?

  func reset() {
    entries.removeAll()
    settleDeadline = nil
  }

  func valueToWrite(forSlot slot: Int, marker: Int32, now: Float) -> AnimatedMarkerColor {
    guard var entry = entries[slot] else {
      entries[slot] = Entry(fromMarker: marker, toMarker: marker, startTime: now)
      return AnimatedMarkerColor(fromMarker: marker, toMarker: marker, startTime: now)
    }
    if entry.toMarker != marker {
      entry = Entry(fromMarker: entry.toMarker, toMarker: marker, startTime: now)
      entries[slot] = entry
      settleDeadline = max(settleDeadline ?? -.infinity, now + Float(transitionDuration))
    }
    return AnimatedMarkerColor(fromMarker: entry.fromMarker, toMarker: entry.toMarker, startTime: entry.startTime)
  }

  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }
}
