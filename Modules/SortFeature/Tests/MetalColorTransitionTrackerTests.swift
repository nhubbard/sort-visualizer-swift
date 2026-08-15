import Testing

@testable import SortFeature

private func isClose(_ lhs: SIMD4<Float>, _ rhs: SIMD4<Float>, tolerance: Float = 0.0001) -> Bool {
  let delta = lhs - rhs
  return abs(delta.x) < tolerance && abs(delta.y) < tolerance && abs(delta.z) < tolerance
    && abs(delta.w) < tolerance
}

/// Covers exactly the bookkeeping half of `MetalColorTransitionTracker` — deciding when a new
/// target starts a fresh fade, and what `from`/`to`/`startTime` triple gets written. This is still
/// 100% CPU-side logic after the GPU-driven easing redesign; only the per-frame resolution
/// (`resolveAnimated4` in `AnimatedField.h`) moved to the shader, which these tests can't reach
/// directly — see the per-renderer shader-parity tests for coverage of that half.
@Suite
struct MetalColorTransitionTrackerTests {
  private static let gray = SIMD4<Float>(0.82, 0.82, 0.86, 1)
  private static let red = SIMD4<Float>(0.95, 0.38, 0.38, 1)
  private static let blue = SIMD4<Float>(0.38, 0.58, 0.95, 1)

  @MainActor
  @Test
  func firstColorForASlotShowsImmediatelyWithNoFade() {
    let tracker = MetalColorTransitionTracker()
    // Nothing to fade FROM yet — a slot's very first color must appear immediately, not fade in
    // from black/zero: `from == to` resolves to that value at any `t`.
    let written = tracker.valueToWrite(forSlot: 0, target: Self.red, now: 0)
    #expect(written.from == Self.red)
    #expect(written.to == Self.red)
    #expect(!tracker.isActive(now: 0))
  }

  @MainActor
  @Test
  func laterColorChangeFadesInsteadOfSnapping() throws {
    let tracker = MetalColorTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.gray, now: 0)

    let restarted = tracker.valueToWrite(forSlot: 0, target: Self.red, now: 0)
    #expect(restarted.from == Self.gray, "the fade must start from the OLD color")
    #expect(restarted.to == Self.red)
    #expect(tracker.isActive(now: 0))

    let midChange = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 0.06))  // half of 0.12s
    #expect(!isClose(midChange, Self.gray), "should have moved away from the starting color")
    #expect(!isClose(midChange, Self.red), "should not have reached the target color yet")
    #expect(tracker.isActive(now: 0.06))

    let settled = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 1))  // overshoots -> clamps to target
    #expect(isClose(settled, Self.red))
    #expect(!tracker.isActive(now: 1))
  }

  @MainActor
  @Test
  func targetChangingMidFadeRestartsFromCurrentDisplayedColorNotAPop() throws {
    let tracker = MetalColorTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.gray, now: 0)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.red, now: 0)
    let partial = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 0.06))  // halfway from gray to red

    let writtenAtRetarget = tracker.valueToWrite(forSlot: 0, target: Self.blue, now: 0.06)
    #expect(
      isClose(writtenAtRetarget.from, partial),
      "retargeting mid-fade must continue from the current displayed color, not pop back to gray or jump to blue"
    )
    #expect(writtenAtRetarget.to == Self.blue)

    let settled = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 0.06 + 1))
    #expect(isClose(settled, Self.blue))
  }

  @MainActor
  @Test
  func resetClearsAllTrackedSlots() {
    let tracker = MetalColorTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.gray, now: 0)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.red, now: 0)
    #expect(tracker.isActive(now: 0))

    tracker.reset()
    #expect(!tracker.isActive(now: 0))
    // Slot 0 is treated as a fresh first-ever paint again — shows immediately, no fade.
    let written = tracker.valueToWrite(forSlot: 0, target: Self.blue, now: 0)
    #expect(written.from == Self.blue)
    #expect(written.to == Self.blue)
  }

  /// Regression guard for independent per-slot bookkeeping: a slot touched out of order and far
  /// from zero must still track independently of every other slot, and a never-touched slot
  /// (including one far beyond any real slot count) must report no resolved value rather than
  /// crashing or inheriting another slot's state.
  @MainActor
  @Test
  func nonZeroAndUntouchedSlotsTrackIndependently() throws {
    let tracker = MetalColorTransitionTracker()

    let written5 = tracker.valueToWrite(forSlot: 5, target: Self.red, now: 0)
    #expect(written5.from == Self.red && written5.to == Self.red)
    #expect(tracker.resolvedValueForTesting(forSlot: 0, now: 0) == nil, "slot 0 was never touched")
    #expect(
      tracker.resolvedValueForTesting(forSlot: 100, now: 0) == nil,
      "far-beyond-capacity slot must not crash")

    // Slot 2, touched afterward, must be its own independent fresh-paint, not somehow inherit
    // slot 5's already-settled state.
    let written2 = tracker.valueToWrite(forSlot: 2, target: Self.blue, now: 0)
    #expect(written2.from == Self.blue && written2.to == Self.blue)

    // Retargeting slot 5 mid-stream must not disturb slot 2's already-settled entry.
    _ = tracker.valueToWrite(forSlot: 5, target: Self.gray, now: 0)
    let slot5Settled = try #require(tracker.resolvedValueForTesting(forSlot: 5, now: 1))
    #expect(isClose(slot5Settled, Self.gray))
    #expect(tracker.resolvedValueForTesting(forSlot: 2, now: 1) == Self.blue)
  }
}
