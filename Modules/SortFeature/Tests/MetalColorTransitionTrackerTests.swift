import Testing

@testable import SortFeature

private func isClose(_ lhs: SIMD4<Float>, _ rhs: SIMD4<Float>, tolerance: Float = 0.0001) -> Bool {
  let delta = lhs - rhs
  return abs(delta.x) < tolerance && abs(delta.y) < tolerance && abs(delta.z) < tolerance
    && abs(delta.w) < tolerance
}

@Suite
struct MetalColorTransitionTrackerTests {
  private static let gray = SIMD4<Float>(0.82, 0.82, 0.86, 1)
  private static let red = SIMD4<Float>(0.95, 0.38, 0.38, 1)
  private static let blue = SIMD4<Float>(0.38, 0.58, 0.95, 1)

  @MainActor
  @Test
  func firstColorForASlotShowsImmediatelyWithNoFade() {
    let tracker = MetalColorTransitionTracker()
    // Nothing to fade FROM yet — a slot's very first color must appear immediately, not
    // fade in from black/zero, or every new run would visibly fade in on first paint.
    #expect(tracker.valueToWrite(forSlot: 0, target: Self.red) == Self.red)
    #expect(!tracker.isActive)
  }

  @MainActor
  @Test
  func laterColorChangeFadesInsteadOfSnapping() throws {
    let tracker = MetalColorTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.gray)

    let firstWrite = tracker.valueToWrite(forSlot: 0, target: Self.red)
    #expect(firstWrite == Self.gray, "must still show the OLD color the instant the target changes")
    #expect(tracker.isActive)

    let midChange = try #require(tracker.advance(elapsed: 0.06)[0])  // half of the 0.12s duration
    #expect(!isClose(midChange, Self.gray), "should have moved away from the starting color")
    #expect(!isClose(midChange, Self.red), "should not have reached the target color yet")
    #expect(tracker.isActive)

    let settled = try #require(tracker.advance(elapsed: 1)[0])  // overshoots -> clamps to target
    #expect(isClose(settled, Self.red))
    #expect(!tracker.isActive)
  }

  @MainActor
  @Test
  func targetChangingMidFadeRestartsFromCurrentDisplayedColorNotAPop() throws {
    let tracker = MetalColorTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.gray)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.red)
    let partial = try #require(tracker.advance(elapsed: 0.06)[0])  // halfway from gray to red

    let writtenAtRetarget = tracker.valueToWrite(forSlot: 0, target: Self.blue)
    #expect(
      writtenAtRetarget == partial,
      "retargeting mid-fade must continue from the current displayed color, not pop back to gray or jump to blue"
    )

    let settled = try #require(tracker.advance(elapsed: 1)[0])
    #expect(isClose(settled, Self.blue))
  }

  @MainActor
  @Test
  func resetClearsAllTrackedSlots() {
    let tracker = MetalColorTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.gray)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.red)
    #expect(tracker.isActive)

    tracker.reset()
    #expect(!tracker.isActive)
    // Slot 0 is treated as a fresh first-ever paint again — shows immediately, no fade.
    #expect(tracker.valueToWrite(forSlot: 0, target: Self.blue) == Self.blue)
  }

  /// Regression guard for the backing-storage change (`Dictionary<Int, Entry>` → `[Entry?]`,
  /// grown lazily by `ensureCapacity`): a slot touched out of order and far from zero must still
  /// track independently of every other slot, and `displayed(forSlot:)` for a slot that's never
  /// been touched at all (including one beyond the array's current length) must return `nil`
  /// rather than crashing on an out-of-bounds access.
  @MainActor
  @Test
  func nonZeroAndUntouchedSlotsTrackIndependently() throws {
    let tracker = MetalColorTransitionTracker()

    // Touching slot 5 first must grow the backing storage correctly, not assume slot 0 exists.
    #expect(tracker.valueToWrite(forSlot: 5, target: Self.red) == Self.red)
    #expect(tracker.displayed(forSlot: 0) == nil, "slot 0 was never touched")
    #expect(tracker.displayed(forSlot: 100) == nil, "far-beyond-capacity slot must not crash")

    // Slot 2, touched afterward, must be its own independent fresh-paint, not somehow inherit
    // slot 5's already-settled state.
    #expect(tracker.valueToWrite(forSlot: 2, target: Self.blue) == Self.blue)

    // Retargeting slot 5 mid-stream must not disturb slot 2's already-settled entry.
    _ = tracker.valueToWrite(forSlot: 5, target: Self.gray)
    let changes = tracker.advance(elapsed: 1)
    #expect(isClose(try #require(changes[5]), Self.gray))
    #expect(changes[2] == nil, "slot 2 was never mid-fade, so advance() must not report it as changed")
    #expect(tracker.displayed(forSlot: 2) == Self.blue)
  }
}
