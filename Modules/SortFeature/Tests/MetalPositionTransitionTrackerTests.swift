import Testing

@testable import SortFeature

private func isClose(_ lhs: SIMD2<Float>, _ rhs: SIMD2<Float>, tolerance: Float = 0.0001) -> Bool {
  let delta = lhs - rhs
  return abs(delta.x) < tolerance && abs(delta.y) < tolerance
}

/// Mirrors `MetalColorTransitionTrackerTests.swift` test-for-test — same bookkeeping contract,
/// only the `Value` shape (a 2D point instead of an RGBA color) differs. See that file's own doc
/// comment for why these tests only cover the CPU-side bookkeeping half, not the GPU-side
/// resolution.
@Suite
struct MetalPositionTransitionTrackerTests {
  private static let origin = SIMD2<Float>(10, 20)
  private static let farRight = SIMD2<Float>(200, 20)
  private static let farUp = SIMD2<Float>(10, 200)

  @MainActor
  @Test
  func firstPositionForASlotShowsImmediatelyWithNoFade() {
    let tracker = MetalPositionTransitionTracker()
    let written = tracker.valueToWrite(forSlot: 0, target: Self.farRight, now: 0)
    #expect(written.from == Self.farRight)
    #expect(written.to == Self.farRight)
    #expect(!tracker.isActive(now: 0))
  }

  @MainActor
  @Test
  func laterPositionChangeFadesInsteadOfSnapping() throws {
    let tracker = MetalPositionTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.origin, now: 0)

    let restarted = tracker.valueToWrite(forSlot: 0, target: Self.farRight, now: 0)
    #expect(restarted.from == Self.origin, "the fade must start from the OLD position")
    #expect(restarted.to == Self.farRight)
    #expect(tracker.isActive(now: 0))

    let midChange = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 0.06))  // half of 0.12s
    #expect(!isClose(midChange, Self.origin), "should have moved away from the starting position")
    #expect(!isClose(midChange, Self.farRight), "should not have reached the target position yet")
    #expect(tracker.isActive(now: 0.06))

    let settled = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 1))  // overshoots -> clamps to target
    #expect(isClose(settled, Self.farRight))
    #expect(!tracker.isActive(now: 1))
  }

  @MainActor
  @Test
  func targetChangingMidFadeRestartsFromCurrentDisplayedPositionNotAPop() throws {
    let tracker = MetalPositionTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.origin, now: 0)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.farRight, now: 0)
    let partial = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 0.06))  // halfway from origin to farRight

    let writtenAtRetarget = tracker.valueToWrite(forSlot: 0, target: Self.farUp, now: 0.06)
    #expect(
      isClose(writtenAtRetarget.from, partial),
      "retargeting mid-fade must continue from the current displayed position, not pop back to origin or jump to farUp"
    )
    #expect(writtenAtRetarget.to == Self.farUp)

    let settled = try #require(tracker.resolvedValueForTesting(forSlot: 0, now: 0.06 + 1))
    #expect(isClose(settled, Self.farUp))
  }

  @MainActor
  @Test
  func resetClearsAllTrackedSlots() {
    let tracker = MetalPositionTransitionTracker()
    _ = tracker.valueToWrite(forSlot: 0, target: Self.origin, now: 0)
    _ = tracker.valueToWrite(forSlot: 0, target: Self.farRight, now: 0)
    #expect(tracker.isActive(now: 0))

    tracker.reset()
    #expect(!tracker.isActive(now: 0))
    let written = tracker.valueToWrite(forSlot: 0, target: Self.farUp, now: 0)
    #expect(written.from == Self.farUp)
    #expect(written.to == Self.farUp)
  }

  @MainActor
  @Test
  func nonZeroAndUntouchedSlotsTrackIndependently() throws {
    let tracker = MetalPositionTransitionTracker()

    let written5 = tracker.valueToWrite(forSlot: 5, target: Self.farRight, now: 0)
    #expect(written5.from == Self.farRight && written5.to == Self.farRight)
    #expect(tracker.resolvedValueForTesting(forSlot: 0, now: 0) == nil, "slot 0 was never touched")
    #expect(
      tracker.resolvedValueForTesting(forSlot: 100, now: 0) == nil,
      "far-beyond-capacity slot must not crash")

    let written2 = tracker.valueToWrite(forSlot: 2, target: Self.farUp, now: 0)
    #expect(written2.from == Self.farUp && written2.to == Self.farUp)

    _ = tracker.valueToWrite(forSlot: 5, target: Self.origin, now: 0)
    let slot5Settled = try #require(tracker.resolvedValueForTesting(forSlot: 5, now: 1))
    #expect(isClose(slot5Settled, Self.origin))
    #expect(tracker.resolvedValueForTesting(forSlot: 2, now: 1) == Self.farUp)
  }
}
