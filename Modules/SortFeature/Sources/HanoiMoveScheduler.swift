import Foundation

/// A short, per-slot queue of position waypoints for `MetalHanoiTowersRenderer` — the mechanism
/// behind its lift-obstacles/carry/place/restore choreography. Wraps a plain
/// `MetalTransitionTracker<SIMD2<Float>>` (`MetalColorTransitionTracker.swift`) for the actual
/// easing of whichever leg is current; this type only adds "and once you've been heading toward
/// this leg's target for `holdDuration` seconds, retarget to the next one."
///
/// Deliberately has no separate "reduce motion at high playback speed" mode: if a later operation
/// touches a slot before its current choreography finishes, `schedule` simply overwrites the
/// queue and retargets immediately — the same interrupt-and-retarget behavior
/// `MetalTransitionTracker.valueToWrite` already has. At fast playback, legs compress into a blur
/// instead of ever fully completing, which degrades gracefully rather than needing to be
/// special-cased — no other renderer in this file's family has a "reduced motion" branch either.
@MainActor
final class HanoiMoveScheduler {
  struct Waypoint {
    var target: SIMD2<Float>
    /// How long to sit "in transit toward" this waypoint before advancing to the next one in the
    /// queue — independent of how long the underlying tracker's own fade actually takes, since
    /// `MetalTransitionTracker` exposes no per-slot "has this settled yet" query.
    var holdDuration: TimeInterval
  }

  private var queues: [Int: [Waypoint]] = [:]
  private var elapsedInLeg: [Int: TimeInterval] = [:]
  private let positions = MetalTransitionTracker<SIMD2<Float>>()

  func reset() {
    queues.removeAll()
    elapsedInLeg.removeAll()
    positions.reset()
  }

  /// Replaces any in-flight sequence for `slot` and immediately targets the first waypoint.
  func schedule(slot: Int, waypoints: [Waypoint]) {
    guard let first = waypoints.first else { return }
    queues[slot] = waypoints
    elapsedInLeg[slot] = 0
    _ = positions.valueToWrite(forSlot: slot, target: first.target)
  }

  /// For slots with no in-flight choreography — the resting-state repaint every OTHER slot needs
  /// on every `apply`/`reset`, same as `MetalShapeRenderer.writeInstance` does unconditionally.
  func setDirect(slot: Int, target: SIMD2<Float>) {
    guard (queues[slot] ?? []).count <= 1 else { return }
    queues[slot] = nil
    _ = positions.valueToWrite(forSlot: slot, target: target)
  }

  var isActive: Bool { positions.isActive }

  func displayed(forSlot slot: Int) -> SIMD2<Float>? {
    positions.displayed(forSlot: slot)
  }

  /// Advances every in-flight leg timer, retargeting any slot whose current leg's `holdDuration`
  /// has elapsed, then advances the underlying position tracker — same shape as
  /// `MetalTransitionTracker.advance(elapsed:)`, returning only the slots that actually moved.
  func advance(elapsed: TimeInterval) -> [Int: SIMD2<Float>] {
    for slot in queues.keys {
      guard var queue = queues[slot], queue.count > 1 else { continue }
      elapsedInLeg[slot, default: 0] += elapsed
      if elapsedInLeg[slot]! >= queue[0].holdDuration {
        elapsedInLeg[slot] = 0
        queue.removeFirst()
        queues[slot] = queue
        _ = positions.valueToWrite(forSlot: slot, target: queue[0].target)
      }
    }
    return positions.advance(elapsed: elapsed)
  }
}
