import Foundation

/// A fixed 2-leg animated origin for `MetalHanoiTowersRenderer`'s lift-obstacles/carry/place/
/// restore choreography, resolved every frame by `hanoi_vertex` (`resolveHanoiOrigin`,
/// `AnimatedField.h`) instead of a CPU-side per-frame sweep — see `MetalColorSourceTracker`'s doc
/// comment for the full rationale behind resolving animation on the GPU.
///
/// Every real caller (`MetalHanoiTowersRenderer.choreographSwap`'s cross-tower swap,
/// `scheduleObstacle`) schedules exactly 2 legs: ease `transitionDuration` seconds toward
/// `leg0To`, sit static until `leg0Hold` elapses, then ease a fresh `transitionDuration` seconds
/// toward `leg1To`. Encoding that fixed shape directly (rather than a generic variable-length
/// queue, which is what this used to be before the GPU-driven redesign) means the shader can
/// resolve the whole 2-leg timeline itself, with no per-frame CPU bookkeeping of "has this leg's
/// hold elapsed yet" — that per-frame check would have reintroduced exactly the O(frames ×
/// active-instances) cost this redesign exists to eliminate, since every in-flight obstacle would
/// need checking every frame regardless of how the position itself gets resolved.
///
/// `leg0Hold` MUST be `>= transitionDuration` for leg 1 to visually continue from exactly
/// `leg0To` rather than popping (true for every real usage today: `legDuration = 0.15`/
/// `legDuration * 2 = 0.3`, both `> transitionDuration = 0.12`) — see
/// `MetalHanoiTowersRenderer.legDuration`'s own doc comment.
struct HanoiOrigin {
  var leg0From: SIMD2<Float>
  var leg0To: SIMD2<Float>
  var leg1To: SIMD2<Float>
  var leg0Hold: Float
  var startTime: Float
}

/// Thin wrapper around a per-slot array of `HanoiOrigin`s — replaces the old generic `[Waypoint]`
/// queue plus its `advance(elapsed:)` leg-advancement sweep, both retired now that every real
/// usage was already always exactly 2 legs (see `HanoiOrigin`'s own doc comment) and the shader
/// does all per-frame resolution itself.
///
/// Backed by `[HanoiOrigin?]` rather than `[Int: HanoiOrigin]` — slots are dense, contiguous
/// `0..<count` indices, so direct indexing beats a Dictionary's hash + bucket search. A prior
/// attempt at this exact swap (`8ecdf2e`, reverted by `d8a6d80`) measured ~4x WORSE under this
/// project's Debug/`-Onone` build, but that was on the old *generic*
/// `MetalTransitionTracker<Value: SIMD>` — under `-Onone` Swift doesn't specialize generics, so
/// `Optional<Entry<Value>>` fell back to runtime value-witness-table dispatch on every array
/// access. `HanoiOrigin` is a concrete, non-generic struct (post `f61bc5d`'s de-genericization),
/// so `Optional<HanoiOrigin>` gets its compact fixed layout at compile time regardless of
/// optimization level — confirmed via `HanoiStressHarnessTests` before/after, not assumed.
@MainActor
final class HanoiMoveScheduler {
  private var origins: [HanoiOrigin?] = []
  /// The latest instant at which any tracked entry could still be mid-fade — an O(1) substitute
  /// for scanning every entry every frame. Only ever grows, so once `now` passes it, NOTHING can
  /// still be animating — `isActive` reporting `false` is exact, not approximate.
  private var settleDeadline: Float?

  func reset() {
    origins.removeAll(keepingCapacity: true)
    settleDeadline = nil
  }

  /// Grows `origins` up to and including `slot`, leaving new entries `nil` — matches a
  /// Dictionary's own "key absent" semantics for a slot that's never been touched. Every real
  /// caller repopulates every slot via `setDirect`/`schedule` immediately after `reset()`, so this
  /// never leaves a real gap in practice.
  private func ensureCapacity(_ slot: Int) {
    if slot >= origins.count {
      origins.append(contentsOf: repeatElement(nil, count: slot - origins.count + 1))
    }
  }

  /// Replaces any in-flight choreography for `slot` and starts a fresh 2-leg animation, continuing
  /// from wherever `slot` is currently, visually sitting (via `resolvedOrigin`) rather than
  /// popping — the same interrupt-and-retarget contract every other tracker in this file's family
  /// has. Returns the origin just written so callers don't need a second lookup to hand it to
  /// `MetalHanoiTowersRenderer.writeInstance`.
  @discardableResult
  func schedule(
    slot: Int, leg0Target: SIMD2<Float>, leg0Hold: TimeInterval, leg1Target: SIMD2<Float>,
    now: Float
  ) -> HanoiOrigin {
    let from = resolvedOrigin(forSlot: slot, now: now) ?? leg0Target
    let origin = HanoiOrigin(
      leg0From: from, leg0To: leg0Target, leg1To: leg1Target, leg0Hold: Float(leg0Hold),
      startTime: now)
    ensureCapacity(slot)
    origins[slot] = origin
    settleDeadline = max(
      settleDeadline ?? -.infinity, now + Float(leg0Hold) + Float(transitionDuration))
    return origin
  }

  /// For slots with no in-flight choreography — the resting-state repaint every OTHER slot needs
  /// on every `apply`/`reset`, same as `MetalShapeRenderer.writeInstance` does unconditionally.
  /// Guarded the same way the pre-redesign `setDirect` was: don't clobber an in-flight 2-leg
  /// choreography that hasn't reached (or settled at) leg 1 yet. Returns the origin now in effect
  /// for `slot` (either the untouched existing one, or the fresh resting-state one just written).
  @discardableResult
  func setDirect(slot: Int, target: SIMD2<Float>, now: Float) -> HanoiOrigin {
    ensureCapacity(slot)
    if let existing = origins[slot],
      now < existing.startTime + existing.leg0Hold + Float(transitionDuration) {
      return existing
    }
    let origin = HanoiOrigin(
      leg0From: target, leg0To: target, leg1To: target, leg0Hold: 0, startTime: now)
    origins[slot] = origin
    return origin
  }

  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }

  /// Production/test seam: the raw current `HanoiOrigin` for `slot`, exactly as it'll be written
  /// into the GPU buffer — `nil` only if `slot` has never been touched at all (in practice, every
  /// slot gets at least one `setDirect` call during `reset()`, so this is mostly a defensive nil).
  func origin(forSlot slot: Int) -> HanoiOrigin? {
    guard slot < origins.count else { return nil }
    return origins[slot]
  }

  /// The CPU reference computation — identical math to `AnimatedField.h`'s `resolveHanoiOrigin` —
  /// used only at retarget time (`schedule` above, to continue smoothly instead of popping) and
  /// by tests, never on a per-frame production path.
  func resolvedOrigin(forSlot slot: Int, now: Float) -> SIMD2<Float>? {
    guard slot < origins.count, let origin = origins[slot] else { return nil }
    let t = now - origin.startTime
    if t < origin.leg0Hold {
      let localT = min(max(t / Float(transitionDuration), 0), 1)
      let eased = easeInOutCubic(localT)
      return origin.leg0From + (origin.leg0To - origin.leg0From) * SIMD2<Float>(repeating: eased)
    }
    let leg1T = t - origin.leg0Hold
    // Fully settled: `easeInOutCubic(1) == 1` exactly (verified, not approximated — see its own
    // doc comment), so a clamped `localT` of 1 always resolves to exactly `leg1To` anyway. Skip
    // the divide/clamp/cubic-eval for this case rather than compute a result that's already known
    // — cheap on its own, but `schedule` calls this once per obstacle per swap, so it's worth
    // skipping at that call volume.
    guard leg1T < Float(transitionDuration) else { return origin.leg1To }
    let localT = leg1T / Float(transitionDuration)
    let eased = easeInOutCubic(localT)
    return origin.leg0To + (origin.leg1To - origin.leg0To) * SIMD2<Float>(repeating: eased)
  }
}
