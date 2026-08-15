import Foundation

/// The position/size/point counterpart to `MetalColorTransitionTracker` — see that class's doc
/// comment (`MetalColorTransitionTracker.swift`, same file as the shared `transitionDuration`/
/// `easeInOutCubic` this class reuses) for the full rationale behind resolving `(from, to,
/// startTime)` triples on the GPU every frame instead of sweeping every active entry on the CPU.
/// Every renderer easing a position/size/point (`MetalBarRenderer`, `MetalShapeRenderer`,
/// `MetalTriangleRenderer`, `MetalDisparityChordsRenderer`) uses this type; every renderer easing
/// a color uses `MetalColorTransitionTracker` instead — same shape, kept as two small
/// hand-duplicated classes rather than one shared abstraction (see that class's doc comment for
/// why sharing one generic implementation is exactly the cost this design avoids).
@MainActor
final class MetalPositionTransitionTracker {
  private struct Entry {
    var from: SIMD2<Float>
    var to: SIMD2<Float>
    var startTime: Float
  }

  private var entries: [Int: Entry] = [:]
  /// See `MetalColorTransitionTracker.settleDeadline`'s doc comment — identical role here.
  private var settleDeadline: Float?

  func reset() {
    entries.removeAll()
    settleDeadline = nil
  }

  /// Called every time a renderer would otherwise write `target` directly into its GPU buffer.
  /// Returns the `(from, to, startTime)` triple to write THIS call — the shader resolves it into
  /// an actual displayed position every subsequent frame on its own.
  func valueToWrite(forSlot slot: Int, target: SIMD2<Float>, now: Float) -> AnimatedFloat2 {
    guard var entry = entries[slot] else {
      // First-ever value for this slot — nothing to fade from, so show it immediately: `from ==
      // to` resolves to that same value at any `t`, no special-casing needed on the GPU side.
      let fresh = Entry(from: target, to: target, startTime: now)
      entries[slot] = fresh
      return AnimatedFloat2(from: target, to: target, startTime: now)
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
    return AnimatedFloat2(from: entry.from, to: entry.to, startTime: entry.startTime)
  }

  /// The one-shot CPU reference computation — identical math to `AnimatedField.h`'s
  /// `resolveAnimated2` — used only at retarget time (see `valueToWrite` above) and by tests
  /// (`resolvedValueForTesting`), never on a per-frame path.
  private func resolvedValue(_ entry: Entry, now: Float) -> SIMD2<Float> {
    let t = min(max((now - entry.startTime) / Float(transitionDuration), 0), 1)
    let eased = easeInOutCubic(t)
    return entry.from + (entry.to - entry.from) * SIMD2<Float>(repeating: eased)
  }

  /// O(1) — whether ANY slot could still be mid-fade at `now`. See `MetalColorTransitionTracker
  /// .isActive`'s doc comment.
  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }

  /// Test-only — see `MetalColorTransitionTracker.resolvedValueForTesting`'s doc comment.
  func resolvedValueForTesting(forSlot slot: Int, now: Float) -> SIMD2<Float>? {
    entries[slot].map { resolvedValue($0, now: now) }
  }
}
