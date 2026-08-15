import Foundation

/// Eases each GPU instance slot's rendered POSITION-shaped field (origin, size, a triangle/line
/// point) toward its latest target over `transitionDuration` instead of snapping instantly — a
/// teleporting point/dot otherwise reads jarringly against every OTHER eased field on the same
/// instance.
///
/// A concrete (non-generic) class hardcoded to `SIMD2<Float>` — see `MetalColorTransitionTracker`'s
/// own doc comment (`MetalColorTransitionTracker.swift`, same file as the shared `transitionDuration`/
/// `easeInOutCubic` this class reuses) for why this is deliberately NOT unified with that class
/// behind one generic `MetalTransitionTracker<Value: SIMD>` type anymore: doing so paid real
/// runtime generic-metadata dispatch cost on every call under this project's Debug (`-Onone`)
/// build, confirmed directly via a Hanoi Towers stress-profiling round. Every renderer easing a
/// position/size/point (`MetalBarRenderer`, `MetalShapeRenderer`, `MetalTriangleRenderer`,
/// `MetalDisparityChordsRenderer`, `HanoiMoveScheduler`) uses this type; every renderer easing a
/// color uses `MetalColorTransitionTracker` instead — same shape, kept as two small hand-duplicated
/// classes rather than one shared abstraction.
@MainActor
final class MetalPositionTransitionTracker {
  private struct Entry {
    var from: SIMD2<Float>
    var to: SIMD2<Float>
    var displayed: SIMD2<Float>
    var progress: Double
  }

  private var entries: [Int: Entry] = [:]

  /// Whether any slot is still mid-fade — the caller's cue to keep re-arming redraws.
  var isActive: Bool { entries.values.contains { $0.progress < 1 } }

  /// Called from `reset` (a fresh full repaint — new run, resize, scrub) — those are one-time
  /// state resets, not the rapid-flashing case this exists to smooth, so they start clean rather
  /// than fading from whatever the previous run last displayed.
  func reset() {
    entries.removeAll()
  }

  /// Called every time a renderer would otherwise write `target` directly into its GPU buffer.
  /// Returns the value that should actually be written THIS call.
  func valueToWrite(forSlot slot: Int, target: SIMD2<Float>) -> SIMD2<Float> {
    guard var entry = entries[slot] else {
      // First-ever value for this slot — nothing to fade from, so show it immediately.
      entries[slot] = Entry(from: target, to: target, displayed: target, progress: 1)
      return target
    }
    if entry.to != target {
      // Restart the fade from wherever it's actually, visually sitting right now — not
      // `entry.from` — so a target that changes again mid-fade continues smoothly instead
      // of popping back to the previous fade's starting value.
      entry.from = entry.displayed
      entry.to = target
      entry.progress = 0
      entries[slot] = entry
    }
    return entry.displayed
  }

  /// Advances every in-flight entry by `elapsed` seconds toward its target, returning the slots
  /// whose displayed value actually moved this tick — the caller only needs to re-write those GPU
  /// buffer entries, not every slot. Settled entries (`progress == 1`) are left in `entries`
  /// rather than removed — a slot's history has to survive so a LATER `valueToWrite` call for
  /// that same slot can still fade from its real last-displayed value instead of treating it as a
  /// fresh first-ever paint. Bounded by slot count either way (keys are just slot indices), so
  /// there's no unbounded-growth concern to trade against that.
  func advance(elapsed: TimeInterval) -> [Int: SIMD2<Float>] {
    guard !entries.isEmpty else { return [:] }
    var changed: [Int: SIMD2<Float>] = [:]
    for (slot, entry) in entries where entry.progress < 1 {
      var updated = entry
      updated.progress = min(1, updated.progress + elapsed / transitionDuration)
      let t = Float(updated.progress)
      let eased = easeInOutCubic(t)
      updated.displayed = updated.from + (updated.to - updated.from) * SIMD2<Float>(repeating: eased)
      entries[slot] = updated
      changed[slot] = updated.displayed
    }
    return changed
  }

  /// The slot's current eased value, even on a tick where it didn't move — needed when a
  /// renderer assembles a complete instance from several independently-tracked fields (e.g.
  /// origin AND size AND color) and only some of them changed this particular tick.
  func displayed(forSlot slot: Int) -> SIMD2<Float>? {
    entries[slot]?.displayed
  }
}
