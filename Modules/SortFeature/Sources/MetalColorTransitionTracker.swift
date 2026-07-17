import Foundation

/// Shared by every `MetalTransitionTracker<Value>` instantiation — Swift doesn't support static
/// stored properties on generic types, so this lives at file scope instead of as a `static let`
/// inside the class itself.
private let transitionDuration: TimeInterval = 0.12

/// Eases each GPU instance slot's rendered value (a color, an origin/size, a triangle point, a
/// line endpoint — anything expressible as a fixed-width float `SIMD` vector) toward its latest
/// target over `transitionDuration`, instead of snapping instantly the moment `apply` touches it —
/// small arrays make for large on-screen bars/shapes, and *anything* snapping on/off every
/// operation at those sizes reads as a high-contrast, high-frequency flash (a real photosensitivity
/// concern, most visible on tiny-array algorithms like Bogo/Bozo Sort) or, for position-driven
/// visualizers, as a point/dot instantly teleporting instead of moving. Pure CPU-side math, no
/// Metal/GPU types, so every renderer (`MetalBarRenderer`, `MetalShapeRenderer`,
/// `MetalTriangleRenderer`, `MetalDisparityChordsRenderer`) shares exactly this one implementation
/// for BOTH color and geometry despite each owning its own differently-shaped GPU instance struct —
/// each field that needs easing just gets its own tracker instance, keyed by `Value`'s shape
/// (`SIMD4<Float>` for color, `SIMD2<Float>` for a point/origin/size).
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
      let t = Float(updated.progress)
      updated.displayed = updated.from + (updated.to - updated.from) * Value(repeating: t)
      entries[slot] = updated
      changed[slot] = updated.displayed
    }
    return changed
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
