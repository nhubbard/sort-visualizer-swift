import Foundation

/// The position/size/point counterpart to `MetalColorSourceTracker`/`MetalMarkerColorTracker` —
/// see `MetalEasingCore.swift` (the shared `transitionDuration`/`easeInOutCubic` this class reuses)
/// for the full rationale behind resolving `(from, to, startTime)` triples on the GPU every frame
/// instead of sweeping every active entry on the CPU. Every renderer easing a position/size/point
/// (`MetalBarRenderer`, `MetalShapeRenderer`, `MetalTriangleRenderer`,
/// `MetalDisparityChordsRenderer`) uses this type; color uses `MetalColorSourceTracker`/
/// `MetalMarkerColorTracker` instead — kept as separate hand-duplicated classes rather than one
/// shared abstraction (a shared generic base would reintroduce the exact Swift generic-dispatch
/// cost the original `MetalTransitionTracker<Value: SIMD>` → concrete-classes split eliminated).
///
/// Backed by `[Entry?]` rather than `[Int: Entry]` — see `HanoiMoveScheduler`'s own doc comment
/// for the full rationale (dense contiguous slot indices, and why the prior generic-type version
/// of this same swap was a real regression while this concrete-struct version isn't). A full
/// ~5-minute Showcase-mode trace (Time Profiler + a dedicated `TickApply`/`TickDispatch` os_signpost
/// comparison in `ReplayEngine`) found this specific tracker's `valueToWrite` costing real,
/// reproducible CPU across ordinary playback — not just Hanoi's synthetic worst case — confirming
/// the win generalizes before making the change, not assuming it from the Hanoi result alone.
@MainActor
final class MetalPositionTransitionTracker {
  private struct Entry {
    var from: SIMD2<Float>
    var to: SIMD2<Float>
    var startTime: Float
  }

  private var entries: [Entry?] = []
  /// The latest instant at which any tracked entry could still be mid-fade — an O(1) substitute
  /// for scanning every entry every frame. Only ever grows (extended at retarget time to
  /// `now + transitionDuration`), so once `now` passes it, NOTHING can still be fading — `isActive`
  /// reporting `false` is exact, not approximate.
  private var settleDeadline: Float?

  func reset() {
    entries.removeAll(keepingCapacity: true)
    settleDeadline = nil
  }

  private func ensureCapacity(_ slot: Int) {
    if slot >= entries.count {
      entries.append(contentsOf: repeatElement(nil, count: slot - entries.count + 1))
    }
  }

  /// Called every time a renderer would otherwise write `target` directly into its GPU buffer.
  /// Returns the `(from, to, startTime)` triple to write THIS call — the shader resolves it into
  /// an actual displayed position every subsequent frame on its own.
  func valueToWrite(forSlot slot: Int, target: SIMD2<Float>, now: Float) -> AnimatedFloat2 {
    ensureCapacity(slot)
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

  /// O(1) — whether ANY slot could still be mid-fade at `now`, the caller's cue to keep re-arming
  /// redraws.
  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }

  /// Test-only: the CPU reference computation at an arbitrary probe time, for asserting the same
  /// bookkeeping behavior these tests always have, and for parity-checking against the shader's
  /// own `resolveAnimated2` in a renderer's shader-parity tests. Not used by any renderer at
  /// runtime — `valueToWrite`'s return value is what actually reaches the GPU.
  func resolvedValueForTesting(forSlot slot: Int, now: Float) -> SIMD2<Float>? {
    guard slot < entries.count, let entry = entries[slot] else { return nil }
    return resolvedValue(entry, now: now)
  }
}

/// The scalar counterpart to `MetalPositionTransitionTracker` above — same bookkeeping, same
/// `[Entry?]` array-backing rationale, just for a single `Float` instead of a `SIMD2<Float>`.
/// First (and so far only) user: `MetalBarRenderer`'s GPU-geometry port, which eases the bar's raw
/// underlying VALUE rather than a CPU-precomputed screen position — see `AnimatedFloat`'s own doc
/// comment for why. Colocated with `MetalPositionTransitionTracker` rather than a new file, same
/// precedent `MetalColorSourceTracker.swift` already set for `MetalMarkerColorTracker`.
@MainActor
final class MetalScalarTransitionTracker {
  private struct Entry {
    var from: Float
    var to: Float
    var startTime: Float
  }

  private var entries: [Entry?] = []
  private var settleDeadline: Float?

  func reset() {
    entries.removeAll(keepingCapacity: true)
    settleDeadline = nil
  }

  private func ensureCapacity(_ slot: Int) {
    if slot >= entries.count {
      entries.append(contentsOf: repeatElement(nil, count: slot - entries.count + 1))
    }
  }

  func valueToWrite(forSlot slot: Int, target: Float, now: Float) -> AnimatedFloat {
    ensureCapacity(slot)
    guard var entry = entries[slot] else {
      let fresh = Entry(from: target, to: target, startTime: now)
      entries[slot] = fresh
      return AnimatedFloat(from: target, to: target, startTime: now)
    }
    if entry.to != target {
      let currentDisplayed = resolvedValue(entry, now: now)
      entry.from = currentDisplayed
      entry.to = target
      entry.startTime = now
      entries[slot] = entry
      settleDeadline = max(settleDeadline ?? -.infinity, now + Float(transitionDuration))
    }
    return AnimatedFloat(from: entry.from, to: entry.to, startTime: entry.startTime)
  }

  private func resolvedValue(_ entry: Entry, now: Float) -> Float {
    let t = min(max((now - entry.startTime) / Float(transitionDuration), 0), 1)
    let eased = easeInOutCubic(t)
    return entry.from + (entry.to - entry.from) * eased
  }

  func isActive(now: Float) -> Bool {
    guard let deadline = settleDeadline else { return false }
    return now < deadline
  }

  func resolvedValueForTesting(forSlot slot: Int, now: Float) -> Float? {
    guard slot < entries.count, let entry = entries[slot] else { return nil }
    return resolvedValue(entry, now: now)
  }
}
