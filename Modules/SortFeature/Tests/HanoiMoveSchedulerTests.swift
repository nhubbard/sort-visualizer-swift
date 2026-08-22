import Testing

@testable import SortFeature

@Suite
struct HanoiMoveSchedulerTests {
  @MainActor
  @Test
  func setDirectMovesImmediatelyWithNoQueue() {
    let scheduler = HanoiMoveScheduler()
    scheduler.setDirect(slot: 0, target: SIMD2(10, 20), now: 0)
    #expect(scheduler.resolvedOrigin(forSlot: 0, now: 0) == SIMD2(10, 20))
  }

  @MainActor
  @Test
  func scheduleTargetsTheFirstLegImmediatelyWhenNothingWasThereBefore() {
    let scheduler = HanoiMoveScheduler()
    // Nothing scheduled for this slot before — `leg0From` falls back to `leg0Target` itself, so
    // there's nothing to fade from (matches every other tracker's "first touch shows immediately").
    scheduler.schedule(slot: 0, leg0Target: SIMD2(5, 5), leg0Hold: 0.2, leg1Target: SIMD2(0, 0), now: 0)
    #expect(scheduler.resolvedOrigin(forSlot: 0, now: 0) == SIMD2(5, 5))
  }

  /// Exercises the actual 2-leg timeline against a REAL prior position (unlike the "nothing was
  /// there before" test above), so leg 0 has something genuine to fade from — the shape every real
  /// `choreographSwap`/`scheduleObstacle` call produces.
  @MainActor
  @Test
  func advancesThroughBothLegsOnTheirOwnTimeline() throws {
    let scheduler = HanoiMoveScheduler()
    scheduler.setDirect(slot: 0, target: SIMD2(0, 0), now: 0)  // a real starting position
    // leg0Hold (0.2) is deliberately > transitionDuration (0.12), matching the documented
    // invariant every real caller already satisfies (0.15/0.3 vs. 0.12).
    scheduler.schedule(
      slot: 0, leg0Target: SIMD2(5, 5), leg0Hold: 0.2, leg1Target: SIMD2(9, 9), now: 0)

    let midLeg0 = try #require(scheduler.resolvedOrigin(forSlot: 0, now: 0.06))  // half of 0.12s
    #expect(midLeg0 != SIMD2(0, 0), "should have moved away from the starting position")
    #expect(midLeg0 != SIMD2(5, 5), "should not have reached leg 0's target yet")

    // At exactly leg0Hold, leg 1 begins — it must continue from exactly leg 0's settled target,
    // not pop, which is the whole reason `leg0Hold >= transitionDuration` is a documented
    // invariant (leg 0's own fade has genuinely finished by this point).
    let atLegBoundary = scheduler.resolvedOrigin(forSlot: 0, now: 0.2)
    #expect(atLegBoundary == SIMD2(5, 5))

    let settled = scheduler.resolvedOrigin(forSlot: 0, now: 1)  // overshoots leg 1's own fade too
    #expect(settled == SIMD2(9, 9), "should have reached leg 1's target after settling")
  }

  @MainActor
  @Test
  func aLaterScheduleInterruptsAndReplacesAnInFlightChoreography() {
    let scheduler = HanoiMoveScheduler()
    scheduler.setDirect(slot: 0, target: SIMD2(0, 0), now: 0)
    scheduler.schedule(
      slot: 0, leg0Target: SIMD2(5, 5), leg0Hold: 10, leg1Target: SIMD2(9, 9), now: 0)
    // Interrupt before the first leg's hold would ever elapse.
    scheduler.schedule(
      slot: 0, leg0Target: SIMD2(1, 1), leg0Hold: 0, leg1Target: SIMD2(1, 1), now: 0.01)
    #expect(scheduler.resolvedOrigin(forSlot: 0, now: 1) == SIMD2(1, 1))
  }

  @MainActor
  @Test
  func independentSlotsDoNotInterfereWithEachOther() {
    let scheduler = HanoiMoveScheduler()
    scheduler.setDirect(slot: 0, target: SIMD2(1, 1), now: 0)
    scheduler.schedule(
      slot: 1, leg0Target: SIMD2(2, 2), leg0Hold: 0.2, leg1Target: SIMD2(3, 3), now: 0)
    #expect(scheduler.resolvedOrigin(forSlot: 0, now: 1) == SIMD2(1, 1))
    #expect(scheduler.resolvedOrigin(forSlot: 1, now: 1) == SIMD2(3, 3))
  }
}
