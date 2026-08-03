import Foundation

/// Shared by every `MetalTransitionTracker<Value>` instantiation — Swift doesn't support static
/// stored properties on generic types, so this lives at file scope instead of as a `static let`
/// inside the class itself.
private let transitionDuration: TimeInterval = 0.12

/// Eases each GPU instance slot's rendered value (color, origin/size, a triangle/line point —
/// anything expressible as a fixed-width float `SIMD` vector) toward its latest target over
/// `transitionDuration` instead of snapping instantly — on small arrays, bars/shapes are large
/// enough that instant snapping reads as a high-contrast flash (a real photosensitivity concern,
/// worst on tiny-array algorithms like Bogo/Bozo Sort) or a teleporting point/dot.
///
/// Pure CPU-side math, no Metal/GPU types — every renderer (`MetalBarRenderer`,
/// `MetalShapeRenderer`, `MetalTriangleRenderer`, `MetalDisparityChordsRenderer`) shares this one
/// implementation for both color and geometry, one tracker instance per eased field, keyed by
/// `Value`'s shape (`SIMD4<Float>` for color, `SIMD2<Float>` for a point).
@MainActor
final class MetalTransitionTracker<Value: SIMD> where Value.Scalar == Float {
  private struct Entry {
    var from: Value
    var to: Value
    var displayed: Value
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
  func valueToWrite(forSlot slot: Int, target: Value) -> Value {
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
  func advance(elapsed: TimeInterval) -> [Int: Value] {
    guard !entries.isEmpty else { return [:] }
    var changed: [Int: Value] = [:]
    for (slot, entry) in entries where entry.progress < 1 {
      var updated = entry
      updated.progress = min(1, updated.progress + elapsed / transitionDuration)
      // Ease-in-out (cubic) rather than linear: with fast-firing highlights retargeting the
      // fade every tick, a linear ramp spends most of its time in a half-blended state and
      // never reads as the FULL target color before the next change arrives — looking like a
      // faint wash instead of a flash. Easing out the back half front-loads the approach so the
      // displayed value reaches near-target quickly and holds there, while still avoiding the
      // instant-snap flash this tracker exists to prevent. Easing in the front half (rather than
      // a pure ease-out) keeps the very start of each fade gentle instead of an abrupt jolt.
      let t = Float(updated.progress)
      let eased = Self.easeInOutCubic(t)
      updated.displayed = updated.from + (updated.to - updated.from) * Value(repeating: eased)
      entries[slot] = updated
      changed[slot] = updated.displayed
    }
    return changed
  }

  private static func easeInOutCubic(_ t: Float) -> Float {
    guard t >= 0.5 else { return 4 * t * t * t }
    let f = -2 * t + 2
    return 1 - f * f * f / 2
  }

  /// The slot's current eased value, even on a tick where it didn't move — needed when a
  /// renderer assembles a complete instance from several independently-tracked fields (e.g.
  /// origin AND size AND color) and only some of them changed this particular tick.
  func displayed(forSlot slot: Int) -> Value? {
    entries[slot]?.displayed
  }
}

/// Color is the one field every renderer eases — kept as its own name for readability at call
/// sites (`colorTransitions`), even though it's just `MetalTransitionTracker<SIMD4<Float>>`.
typealias MetalColorTransitionTracker = MetalTransitionTracker<SIMD4<Float>>
