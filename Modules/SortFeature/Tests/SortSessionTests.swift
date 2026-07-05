import AlgorithmKit
import Foundation
import SettingsKit
import SortEngineKit
import Testing
@testable import SortFeature

/// Bubble sort — mirrors `Legacy/.../BubbleSortImpl.swift`'s logic, duplicated here (rather than
/// depending on `BuiltInAlgorithms`/`ScriptingKit`) so this test target only needs
/// `AlgorithmKit`/`SortEngineKit`.
private struct FakeAlgorithm: SortAlgorithm {
    let id = AlgorithmID(rawValue: "fake")
    var sizeRange: ClosedRange<Int> = 1...512
    var metadata: AlgorithmMetadata {
        AlgorithmMetadata(
            displayName: "Fake",
            category: .weird,
            sizeRange: sizeRange,
            stable: true,
            timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
            spaceComplexity: "O(1)",
            iconName: "fake"
        )
    }

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

@MainActor
private func waitUntilTerminal(_ session: SortSession, timeout: Duration = .seconds(5)) async throws {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        switch session.phase {
        case .complete, .failed:
            return
        default:
            try await Task.sleep(for: .milliseconds(5))
        }
    }
    struct TimedOut: Error {}
    throw TimedOut()
}

/// Very fast playback so tests don't spend real wall-clock time watching bars animate.
@MainActor
private func makeFastSettings() -> AppSettings {
    let store = UserDefaults(suiteName: "SortSessionTests.\(UUID().uuidString)")!
    let settings = AppSettings(store: store)
    settings.playbackSpeed = 100_000
    return settings
}

@MainActor
@Suite
struct SortSessionTests {
    @Test
    func sortEndToEndProducesCorrectlySortedFrame() async throws {
        let session = SortSession(algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: makeFastSettings())
        let size = 9

        await session.start(size: size)
        try await waitUntilTerminal(session)

        guard case let .complete(replay) = session.phase else {
            Issue.record("expected .complete, got \(session.phase)")
            return
        }
        #expect(replay.frame.map(\.value) == Array(1...size))
    }

    /// No confirmation dialog to opt out of anymore (§9 of ARCHITECTURE_V2.md — removed in favor
    /// of ArrayV's own `unreasonableLimit` precedent) — `start(size:)` itself is responsible for
    /// keeping a caller from ever requesting a size the algorithm can't reasonably handle.
    @Test
    func startClampsSizeIntoAlgorithmsSizeRange() async throws {
        let session = SortSession(
            algorithm: FakeAlgorithm(sizeRange: 5...8),
            shuffle: FakeReverseShuffle(),
            settings: makeFastSettings()
        )

        await session.start(size: 999)
        try await waitUntilTerminal(session)

        guard case let .complete(replay) = session.phase else {
            Issue.record("expected .complete, got \(session.phase)")
            return
        }
        #expect(replay.frame.count == 8)
        #expect(replay.frame.map(\.value) == Array(1...8))
    }

    // MARK: - Phase 6: shuffle+sort concatenation

    @Test
    func concatenatedTapeOperationCountEqualsShuffleLengthPlusSortLength() {
        let size = 20
        let algorithm = FakeAlgorithm()
        let shuffle = FakeReverseShuffle()

        var shuffleEngine = RecordingEngine(values: Array(1...size))
        shuffle.record(into: &shuffleEngine)
        let shuffleOperationCount = shuffleEngine.finish().tape.count

        var sortEngine = RecordingEngine(values: shuffleEngine.values)
        algorithm.record(into: &sortEngine)
        let sortOperationCount = sortEngine.finish().tape.count

        let tape = SortSession.makeTape(algorithm: algorithm, shuffle: shuffle, size: size)

        #expect(tape.operations.count == shuffleOperationCount + sortOperationCount)
        #expect(tape.header.sortStartIndex == shuffleOperationCount)
        #expect(tape.header.shuffleID == shuffle.id.rawValue)
        #expect(tape.header.initialValues == Array(1...size))
    }

    @Test(arguments: [
        FakeIdentityShuffle() as any ShuffleAlgorithm,
        FakeReverseShuffle() as any ShuffleAlgorithm,
        FakeRotateShuffle() as any ShuffleAlgorithm,
    ])
    func replayingConcatenatedTapeProducesSortedFrameRegardlessOfShuffle(shuffle: any ShuffleAlgorithm) {
        let size = 15
        let tape = SortSession.makeTape(algorithm: FakeAlgorithm(), shuffle: shuffle, size: size)

        let replay = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { replay.stepForward() }

        #expect(replay.frame.map(\.value) == Array(1...size))
    }
}
