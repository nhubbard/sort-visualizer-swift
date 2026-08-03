import Testing

@testable import SortFeature

@Suite
struct HanoiMoveSchedulerTests {
  @MainActor
  @Test
  func setDirectMovesImmediatelyWithNoQueue() {
    let scheduler = HanoiMoveScheduler()
    scheduler.setDirect(slot: 0, target: SIMD2(10, 20))
    #expect(scheduler.displayed(forSlot: 0) == SIMD2(10, 20))
  }

  @MainActor
  @Test
  func scheduleTargetsTheFirstWaypointImmediately() {
    let scheduler = HanoiMoveScheduler()
    scheduler.schedule(
      slot: 0,
      waypoints: [
        .init(target: SIMD2(5, 5), holdDuration: 0.1),
        .init(target: SIMD2(0, 0), holdDuration: 0),
      ])
    #expect(scheduler.displayed(forSlot: 0) == SIMD2(5, 5))
  }

  @MainActor
  @Test
  func advancesToNextWaypointOnceHoldDurationElapses() {
    let scheduler = HanoiMoveScheduler()
    scheduler.schedule(
      slot: 0,
      waypoints: [
        .init(target: SIMD2(5, 5), holdDuration: 0.1),
        .init(target: SIMD2(9, 9), holdDuration: 0),
      ])
    _ = scheduler.advance(elapsed: 0.05)
    #expect(scheduler.displayed(forSlot: 0) == SIMD2(5, 5), "hold hasn't elapsed yet")

    _ = scheduler.advance(elapsed: 0.06)
    // Overshoot the underlying tracker's own fade too, so `displayed` reflects the settled value.
    _ = scheduler.advance(elapsed: 1)
    #expect(scheduler.displayed(forSlot: 0) == SIMD2(9, 9), "should have advanced to the final waypoint")
  }

  @MainActor
  @Test
  func aLaterScheduleInterruptsAndReplacesAnInFlightQueue() {
    let scheduler = HanoiMoveScheduler()
    scheduler.schedule(
      slot: 0,
      waypoints: [
        .init(target: SIMD2(5, 5), holdDuration: 10),
        .init(target: SIMD2(9, 9), holdDuration: 0),
      ])
    // Interrupt before the first leg's hold would ever elapse.
    scheduler.schedule(slot: 0, waypoints: [.init(target: SIMD2(1, 1), holdDuration: 0)])
    _ = scheduler.advance(elapsed: 1)
    #expect(scheduler.displayed(forSlot: 0) == SIMD2(1, 1))
  }

  @MainActor
  @Test
  func independentSlotsDoNotInterfereWithEachOther() {
    let scheduler = HanoiMoveScheduler()
    scheduler.setDirect(slot: 0, target: SIMD2(1, 1))
    scheduler.schedule(
      slot: 1,
      waypoints: [
        .init(target: SIMD2(2, 2), holdDuration: 0.05),
        .init(target: SIMD2(3, 3), holdDuration: 0),
      ])
    _ = scheduler.advance(elapsed: 1)
    #expect(scheduler.displayed(forSlot: 0) == SIMD2(1, 1))
    #expect(scheduler.displayed(forSlot: 1) == SIMD2(3, 3))
  }
}
