import SortEngineKit
import Testing

@testable import AlgorithmKit

/// Bubble sort — mirrors `SortSessionTests.FakeAlgorithm`'s logic, duplicated here (test targets
/// can't import each other's test code) so this test target only needs `AlgorithmKit`/
/// `SortEngineKit`.
private struct FakeAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "fake")
  let metadata = AlgorithmMetadata(
    displayName: "Fake", category: .exchange, sizeRange: 1...513,
    growthModel: .unconstrained, implementationComplexity: 0, stable: true,
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

private struct FakeIdentityShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "fake-identity")
  let metadata = ShuffleMetadata(displayName: "Fake Identity")
  func record(into engine: inout RecordingEngine) {}
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

/// Records a fixed, non-identity, non-reverse permutation, so tests can prove sortedness holds
/// for an arrangement that isn't one of the two trivial cases above.
private struct FakeRotateShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "fake-rotate")
  let metadata = ShuffleMetadata(displayName: "Fake Rotate")
  func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    for i in 0..<(engine.count - 1) {
      engine.swap(i, engine.count - 1)
    }
  }
}

@Suite
struct TapeFactoryTests {
  @Test
  func concatenatedTapeOperationCountEqualsShuffleLengthPlusSortLength() throws {
    let size = 20
    let algorithm = FakeAlgorithm()
    let shuffle = FakeReverseShuffle()

    var shuffleEngine = RecordingEngine(values: Array(1...size))
    shuffle.record(into: &shuffleEngine)
    shuffleEngine.unmarkAll()  // mirrors makeTape's own trailing cleanup call
    let shuffleOperationCount = shuffleEngine.finish().tape.count

    var sortEngine = RecordingEngine(values: shuffleEngine.values)
    algorithm.record(into: &sortEngine)
    sortEngine.unmarkAll()  // mirrors makeTape's own trailing cleanup call
    let sortOperationCount = sortEngine.finish().tape.count

    let tape = try TapeFactory.makeTape(
      algorithm: algorithm, shuffle: shuffle, size: size,
      operationCap: RecordingEngine.defaultOperationCap)

    #expect(tape.operations.count == shuffleOperationCount + sortOperationCount)
    #expect(tape.header.sortStartIndex == shuffleOperationCount)
    #expect(tape.header.shuffleID == shuffle.id.rawValue)
    #expect(tape.header.initialValues == Array(1...size))
  }

  @MainActor
  @Test(arguments: [
    FakeIdentityShuffle() as any ShuffleAlgorithm,
    FakeReverseShuffle() as any ShuffleAlgorithm,
    FakeRotateShuffle() as any ShuffleAlgorithm
  ])
  func replayingConcatenatedTapeProducesSortedFrameRegardlessOfShuffle(
    shuffle: any ShuffleAlgorithm
  ) throws {
    let size = 15
    let tape = try TapeFactory.makeTape(
      algorithm: FakeAlgorithm(), shuffle: shuffle, size: size,
      operationCap: RecordingEngine.defaultOperationCap)

    let replay = ReplayEngine(tape: tape)
    for _ in 0..<tape.operations.count { replay.stepForward() }

    #expect(replay.frame.map(\.value) == Array(1...size))
  }

  @Test
  func recordingPastTheOperationCapThrowsWithRealCounts() {
    let size = 50
    #expect(throws: TapeRecordingError.self) {
      try TapeFactory.makeTape(
        algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), size: size, operationCap: 5)
    }
  }
}
