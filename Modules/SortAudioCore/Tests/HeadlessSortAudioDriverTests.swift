import AlgorithmKit
import SortEngineKit
import Testing

@testable import SortAudioCore

/// Bubble sort — same shape as `SortSessionTests`/`TapeFactoryTests`' own fakes, duplicated here
/// per this repo's "test targets can't import each other's test code" convention.
private struct FakeAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "fake")
  let metadata = AlgorithmMetadata(
    displayName: "Fake", category: .exchange, sizeRange: 1...16,
    growthModel: .unconstrained, stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)", iconName: "fake"
  )

  func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    for i in 1..<engine.count {
      for j in 0..<(engine.count - i) where engine.compare(j, j + 1) {
        engine.swap(j, j + 1)
      }
    }
  }
}

private struct FakeReverseShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "fake-reverse")
  let metadata = ShuffleMetadata(displayName: "Fake Reverse")
  func record(into engine: inout RecordingEngine) {
    for i in 0..<(engine.count / 2) {
      engine.swap(i, engine.count - 1 - i)
    }
  }
}

private final class FakeSink: SortAudioEventSink, @unchecked Sendable {
  private(set) var events: [SortToneEvent] = []
  func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>) {
    events.append(event)
  }
}

@Suite
struct HeadlessSortAudioDriverTests {
  @Test
  func runCompletesAndEmitsEventsWithinTheArrayRange() async throws {
    let sink = FakeSink()
    let driver = HeadlessSortAudioDriver(sink: sink, noteRange: 36...72)
    driver.speed = 1_000_000  // fast enough to drain the whole (tiny) tape in one tick

    try await driver.run(
      algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), size: 6,
      operationCap: RecordingEngine.defaultOperationCap)

    #expect(!sink.events.isEmpty)
    #expect(sink.events.allSatisfy { $0.range == 1...6 })
    #expect(sink.events.allSatisfy { $0.holdSeconds >= 0.03 })
    #expect(sink.events.allSatisfy { (1...6).contains($0.value) })
  }

  @Test
  func cancellingTheTaskStopsTheDriverPromptly() async throws {
    let sink = FakeSink()
    let driver = HeadlessSortAudioDriver(sink: sink, noteRange: 36...72)
    driver.speed = 1  // deliberately slow so it's still mid-run when cancelled

    let task = Task {
      try await driver.run(
        algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), size: 50,
        operationCap: RecordingEngine.defaultOperationCap)
    }
    try await Task.sleep(for: .milliseconds(50))
    task.cancel()

    await #expect(throws: (any Error).self) {
      try await task.value
    }
  }
}
