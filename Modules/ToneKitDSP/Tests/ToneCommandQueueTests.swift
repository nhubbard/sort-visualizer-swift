import Testing

@testable import ToneKitDSP

@Suite
struct ToneCommandQueueTests {
  @Test
  func popOnEmptyQueueReturnsNil() {
    let queue = ToneCommandQueue()
    #expect(queue.pop() == nil)
  }

  @Test
  func pushThenPopReturnsCommandsInFIFOOrder() {
    let queue = ToneCommandQueue()
    #expect(queue.push(.setFrequency(440)))
    #expect(queue.push(.openGate))
    #expect(queue.push(.closeGate))

    #expect(queue.pop() == .setFrequency(440))
    #expect(queue.pop() == .openGate)
    #expect(queue.pop() == .closeGate)
    #expect(queue.pop() == nil)
  }

  @Test
  func pushBeyondCapacityDropsAndReturnsFalse() {
    let queue = ToneCommandQueue(capacity: 2)
    #expect(queue.push(.openGate))
    #expect(queue.push(.closeGate))
    // Third push exceeds capacity 2 — must be dropped, not silently overwrite an unread slot.
    #expect(!queue.push(.setFrequency(220)))

    #expect(queue.pop() == .openGate)
    #expect(queue.pop() == .closeGate)
    #expect(queue.pop() == nil, "the dropped command must never appear")
  }

  @Test
  func poppingFreesASlotForFurtherPushes() {
    let queue = ToneCommandQueue(capacity: 2)
    #expect(queue.push(.openGate))
    #expect(queue.push(.closeGate))
    #expect(!queue.push(.setFrequency(220)))

    #expect(queue.pop() == .openGate)
    // Freed one slot by popping — a further push should now succeed.
    #expect(queue.push(.setFrequency(220)))
    #expect(queue.pop() == .closeGate)
    #expect(queue.pop() == .setFrequency(220))
  }
}
