import Foundation

/// Shared by both concrete transition trackers below — kept as a plain constant/function rather
/// than inherited from a common (generic or protocol) base, so neither tracker ever touches
/// generic dispatch machinery. Also ported byte-for-byte into `AnimatedField.h` (`easeInOutCubic`)
/// for the GPU-side resolution these trackers no longer perform themselves — see this file's own
/// class doc comment for why steady-state easing moved to the vertex shader.
let transitionDuration: TimeInterval = 0.12

/// Ease-in-out (cubic) rather than linear — see `AnimatedField.h`'s ported copy for the full
/// rationale (kept there since that's where it actually runs every frame now). This CPU-side copy
/// is only ever called at *retarget* time (when a slot's target changes mid-fade, to compute
/// "wherever it's currently, visually sitting" as the new fade's starting point) — never once per
/// frame — so keeping it here alongside the tracker that calls it, rather than trying to share a
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

/// The color counterpart to `resolveAnimated2(_:at:)`.
func resolveAnimated4(_ field: AnimatedFloat4, at now: Float) -> SIMD4<Float> {
  let t = min(max((now - field.startTime) / Float(transitionDuration), 0), 1)
  let eased = easeInOutCubic(t)
  return field.from + (field.to - field.from) * SIMD4<Float>(repeating: eased)
}

/// Tracks each GPU instance slot's animated COLOR as an unresolved `(from, to, startTime)` triple
/// (`AnimatedFloat4`) instead of a continuously-advanced resolved value — the vertex shader
/// resolves it every frame via `AnimatedField.h`'s `resolveAnimated4`, using a `currentTime`
/// uniform. This used to be a per-frame CPU sweep (`advance(elapsed:)`) over every in-flight
/// entry, recomputing and re-writing the GPU buffer for anything still mid-fade — real, measured
/// cost, worst on `MetalHanoiTowersRenderer`'s obstacle choreography (dozens of instances animating
/// at once). Moving resolution to the shader makes steady-state per-frame CPU cost for an
/// animating scene O(1) (fill one uniform struct, reissue the same draw call) regardless of how
/// many instances are mid-transition — the GPU resolves them all in parallel as ordinary vertex
/// work instead.
///
/// The CPU side keeps exactly the bookkeeping that's genuinely rare and needs "current state":
/// deciding, once per touched slot per `SortOperation.apply` (NOT once per frame), whether a new
/// target means starting a fresh fade — and if so, computing the CURRENT interpolated value once
/// (via the private `resolvedValue`, the same math the shader runs) to seed the new fade's `from`,
/// preserving the "continue from wherever it's visually sitting, don't pop back" behavior this
/// tracker has always had.
///
/// A concrete (non-generic) class hardcoded to `SIMD4<Float>`, deliberately NOT sharing an
/// implementation with `MetalPositionTransitionTracker` (`SIMD2<Float>`, same shape otherwise) via
/// a shared generic base or protocol — see this class's own prior doc comment history for why: a
/// shared `MetalTransitionTracker<Value: SIMD>` paid real Swift generic-metadata-cache dispatch
/// overhead under this project's Debug (`-Onone`) build, confirmed via a Hanoi Towers stress-
/// profiling round. Two small, fully concrete classes guarantee zero generic dispatch under any
/// build configuration.
@MainActor
final class MetalColorTransitionTracker {
  private struct Entry {
    var from: SIMD4<Float>
    var to: SIMD4<Float>
    var startTime: Float
  }

  private var entries: [Int: Entry] = [:]
  /// The latest instant at which any tracked entry could still be mid-fade — an O(1) substitute
  /// for scanning every entry's `progress` every frame. Only ever grows (extended at retarget
  /// time to `now + transitionDuration`), matching the "conservatively still active" direction:
  /// once `now` passes it, NOTHING can still be fading, so `isActive` reporting `false` is exact,
  /// not approximate.
  private var settleDeadline: Float?

  func reset() {
    entries.removeAll()
    settleDeadline = nil
  }

  /// Called every time a renderer would otherwise write `target` directly into its GPU buffer.
  /// Returns the `(from, to, startTime)` triple to write THIS call — the shader resolves it into
  /// an actual displayed color every subsequent frame on its own.
  func valueToWrite(forSlot slot: Int, target: SIMD4<Float>, now: Float) -> AnimatedFloat4 {
    guard var entry = entries[slot] else {
      // First-ever value for this slot — nothing to fade from, so show it immediately: `from ==
      // to` resolves to that same value at any `t`, no special-casing needed on the GPU side.
      let fresh = Entry(from: target, to: target, startTime: now)
      entries[slot] = fresh
      return AnimatedFloat4(from: target, to: target, startTime: now)
    }
    if entry.to != target {
      // Restart the fade from wherever it's actually, visually sitting right now — not
      // `entry.from` — so a target that changes again mid-fade continues smoothly instead of
      // popping back to the previous fade's starting value. Computed once, here, rather than
      // read from a continuously-maintained `displayed` field, since nothing maintains one
      // anymore.
      let currentDisplayed = resolvedValue(entry, now: now)
      entry.from = currentDisplayed
      entry.to = target
      entry.startTime = now
      entries[slot] = entry
      settleDeadline = max(settleDeadline ?? -.infinity, now + Float(transitionDuration))
    }
    return AnimatedFloat4(from: entry.from, to: entry.to, startTime: entry.startTime)
  }

  /// The one-shot CPU reference computation — identical math to `AnimatedField.h`'s
  /// `resolveAnimated4` — used only at retarget time (see `valueToWrite` above) and by tests
  /// (`resolvedValueForTesting`), never on a per-frame path.
  private func resolvedValue(_ entry: Entry, now: Float) -> SIMD4<Float> {
    let t = min(max((now - entry.startTime) / Float(transitionDuration), 0), 1)
    let eased = easeInOutCubic(t)
    return entry.from + (entry.to - entry.from) * SIMD4<Float>(repeating: eased)
  }

  /// O(1) — whether ANY slot could still be mid-fade at `now`, the caller's cue to keep
  /// re-arming redraws. Replaces the old per-entry `entries.values.contains { $0.progress < 1 }`
  /// scan, which no longer makes sense once nothing here tracks progress continuously.
  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }

  /// Test-only: the CPU reference computation at an arbitrary probe time, for asserting the same
  /// bookkeeping behavior `MetalColorTransitionTrackerTests` always has, and for parity-checking
  /// against the shader's own `resolveAnimated4` in a renderer's shader-parity tests. Not used by
  /// any renderer at runtime — `valueToWrite`'s return value is what actually reaches the GPU.
  func resolvedValueForTesting(forSlot slot: Int, now: Float) -> SIMD4<Float>? {
    entries[slot].map { resolvedValue($0, now: now) }
  }
}
