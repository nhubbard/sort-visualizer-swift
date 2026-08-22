import Synchronization

/// Bounded single-producer/single-consumer lock-free command queue — the "realtime boundary" from
/// Documentation/docs/architecture/audio.md: `push` is called from the non-realtime control side, `pop` is called
/// only from the realtime render thread. Neither ever blocks, takes a lock, or allocates after
/// `init`; correctness depends entirely on there being exactly one producer and exactly one
/// consumer, which callers must enforce — this type does nothing to detect or prevent a second
/// producer/consumer.
///
/// Backed by raw allocated storage (`UnsafeMutablePointer`), not a Swift `Array` — an `Array`'s
/// copy-on-write buffer header is itself shared mutable state, so concurrent index-disjoint writes
/// from two threads (exactly what `push`/`pop` do) would race on that header even though the actual
/// command slots never overlap. Raw storage has no such shared header.
///
/// `@unchecked Sendable`: the head/tail indices are `Atomic<Int>` with acquire/release ordering at
/// the exact points where ownership of a slot crosses from producer to consumer (and back) — the
/// producer release-stores `tail` after writing a slot and the consumer acquire-loads `tail` before
/// reading it (and symmetrically for `head`), which is what actually makes this safe, not anything
/// the type system verifies on its own.
public final class ToneCommandQueue: @unchecked Sendable {
  /// One more than the number of commands that can actually be held at once — one slot is always
  /// left empty so `head == tail` unambiguously means "empty" without a separate counter.
  private let capacity: Int
  private let storage: UnsafeMutablePointer<ToneCommand?>
  private let head = Atomic<Int>(0)
  private let tail = Atomic<Int>(0)

  public init(capacity: Int = 64) {
    let slots = capacity + 1
    self.capacity = slots
    storage = .allocate(capacity: slots)
    storage.initialize(repeating: nil, count: slots)
  }

  deinit {
    storage.deinitialize(count: capacity)
    storage.deallocate()
  }

  /// Producer side — called from off the render thread. Returns `false` and drops the command if
  /// the queue is full, rather than growing (an allocation this type must never perform after
  /// `init`) or blocking (which would defeat the point of a lock-free queue).
  @discardableResult
  public func push(_ command: ToneCommand) -> Bool {
    let currentTail = tail.load(ordering: .relaxed)
    let nextTail = (currentTail + 1) % capacity
    guard nextTail != head.load(ordering: .acquiring) else { return false }
    storage[currentTail] = command
    tail.store(nextTail, ordering: .releasing)
    return true
  }

  /// Consumer side — must only ever be called from one thread at a time (the realtime render
  /// thread). Returns `nil` once nothing further is due.
  public func pop() -> ToneCommand? {
    let currentHead = head.load(ordering: .relaxed)
    guard currentHead != tail.load(ordering: .acquiring) else { return nil }
    let command = storage[currentHead]
    storage[currentHead] = nil
    head.store((currentHead + 1) % capacity, ordering: .releasing)
    return command
  }
}
