import Testing

@testable import SortFeature

private func isClose(_ lhs: SIMD2<Float>, _ rhs: SIMD2<Float>, tolerance: Float = 0.0001) -> Bool {
  let delta = lhs - rhs
  return abs(delta.x) < tolerance && abs(delta.y) < tolerance
}

/// Mirrors `MetalColorTransitionTrackerTests.swift` test-for-test — the two trackers were split
/// from one generic `MetalTransitionTracker<Value: SIMD>` into two concrete classes (see
/// `MetalPositionTransitionTracker.swift`'s own doc comment for why), so their behavior must stay
/// identical; only the `Value` shape (a 2D point instead of an RGBA color) differs.
@Suite
struct MetalPositionTransitionTrackerTests {
  private static let origin = SIMD2<Float>(10, 20)
  private static let farRight = SIMD2<Float>(200, 20)
  private static let farUp = SIMD2<Float>(10, 200)

  @MainActor
  @Test
  func firstPositionForASlotShowsImmediatelyWithNoFade() {
    let tracker = MetalPositionTransitionTracker()
    // Nothing to fade FROM yet — a slot's very first position must appear immediately, not
    // fade in from zero, or every new run would visibly slide in on first paint.
    #expect(tracker.valueToWrite(forSlot: 0, target: Self.farRight) == Self.farRight)
    #expect(!tracker.isActive)
  }

  @MainActor
  @Test
  func laterPositionChangeFadesInsteadOfSnapping() throws {
    let tracker = MetalPositionTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.origin)

    let firstWrite = tracker.valueToWrite(forSlot: 0, target: Self.farRight)
    #expect(firstWrite == Self.origin, "must still show the OLD position the instant the target changes")
    #expect(tracker.isActive)

    let midChange = try #require(tracker.advance(elapsed: 0.06)[0])  // half of the 0.12s duration
    #expect(!isClose(midChange, Self.origin), "should have moved away from the starting position")
    #expect(!isClose(midChange, Self.farRight), "should not have reached the target position yet")
    #expect(tracker.isActive)

    let settled = try #require(tracker.advance(elapsed: 1)[0])  // overshoots -> clamps to target
    #expect(isClose(settled, Self.farRight))
    #expect(!tracker.isActive)
  }

  @MainActor
  @Test
  func targetChangingMidFadeRestartsFromCurrentDisplayedPositionNotAPop() throws {
    let tracker = MetalPositionTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.origin)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.farRight)
    let partial = try #require(tracker.advance(elapsed: 0.06)[0])  // halfway from origin to farRight

    let writtenAtRetarget = tracker.valueToWrite(forSlot: 0, target: Self.farUp)
    #expect(
      writtenAtRetarget == partial,
      "retargeting mid-fade must continue from the current displayed position, not pop back to origin or jump to farUp"
    )

    let settled = try #require(tracker.advance(elapsed: 1)[0])
    #expect(isClose(settled, Self.farUp))
  }

  @MainActor
  @Test
  func resetClearsAllTrackedSlots() {
    let tracker = MetalPositionTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.origin)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.farRight)
    #expect(tracker.isActive)

    tracker.reset()
    #expect(!tracker.isActive)
    // Slot 0 is treated as a fresh first-ever paint again — shows immediately, no fade.
    #expect(tracker.valueToWrite(forSlot: 0, target: Self.farUp) == Self.farUp)
  }

  @MainActor
  @Test
  func nonZeroAndUntouchedSlotsTrackIndependently() throws {
    let tracker = MetalPositionTransitionTracker()

    // Touching slot 5 first must grow the backing storage correctly, not assume slot 0 exists.
    #expect(tracker.valueToWrite(forSlot: 5, target: Self.farRight) == Self.farRight)
    #expect(tracker.displayed(forSlot: 0) == nil, "slot 0 was never touched")
    #expect(tracker.displayed(forSlot: 100) == nil, "far-beyond-capacity slot must not crash")

    // Slot 2, touched afterward, must be its own independent fresh-paint, not somehow inherit
    // slot 5's already-settled state.
    #expect(tracker.valueToWrite(forSlot: 2, target: Self.farUp) == Self.farUp)

    // Retargeting slot 5 mid-stream must not disturb slot 2's already-settled entry.
    _ = tracker.valueToWrite(forSlot: 5, target: Self.origin)
    let changes = tracker.advance(elapsed: 1)
    #expect(isClose(try #require(changes[5]), Self.origin))
    #expect(changes[2] == nil, "slot 2 was never mid-fade, so advance() must not report it as changed")
    #expect(tracker.displayed(forSlot: 2) == Self.farUp)
  }
}
