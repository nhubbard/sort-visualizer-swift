import AlgorithmKit
import Foundation
import SettingsKit
import SortEngineKit
import Testing
@testable import SortFeature

/// Bubble sort, no confirmation warning — mirrors `Legacy/.../BubbleSortImpl.swift`'s logic,
/// duplicated here (rather than depending on `BuiltInAlgorithms`/`ScriptingKit`) so this test
/// target only needs `AlgorithmKit`/`SortEngineKit`.
private struct FakeAlgorithm: SortAlgorithm {
    let id = AlgorithmID(rawValue: "fake")
    var confirmationWarning: AlgorithmWarning?
    var metadata: AlgorithmMetadata {
        AlgorithmMetadata(
            displayName: "Fake",
            category: .weird,
            sizeRange: 1...512,
            stable: true,
            timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
            spaceComplexity: "O(1)",
            confirmationWarning: confirmationWarning,
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
    func algorithmWithoutWarningSortsEndToEnd() async throws {
        let session = SortSession(algorithm: FakeAlgorithm(), settings: makeFastSettings())
        let input = [5, 3, 8, 1, 9, 2, 7, 4, 6]

        await session.start(values: input)
        try await waitUntilTerminal(session)

        guard case let .complete(replay) = session.phase else {
            Issue.record("expected .complete, got \(session.phase)")
            return
        }
        #expect(replay.frame.map(\.value) == input.sorted())
        #expect(session.gate == .clear)
    }

    @Test
    func algorithmWithWarningBlocksUntilAccepted() async throws {
        let warning = AlgorithmWarning(title: "Careful", message: "This is slow.")
        let session = SortSession(algorithm: FakeAlgorithm(confirmationWarning: warning), settings: makeFastSettings())
        let input = [3, 1, 2]

        await session.start(values: input)

        #expect(session.gate == .needsConfirmation(warning))
        if case .idle = session.phase {
            // expected: recording hasn't started yet
        } else {
            Issue.record("expected .idle while gated, got \(session.phase)")
        }

        await session.acceptWarning()
        try await waitUntilTerminal(session)

        guard case let .complete(replay) = session.phase else {
            Issue.record("expected .complete after accepting, got \(session.phase)")
            return
        }
        #expect(replay.frame.map(\.value) == input.sorted())
        #expect(session.gate == .accepted)
    }

    @Test
    func decliningWarningLeavesSessionIdleWithoutRecording() async throws {
        let warning = AlgorithmWarning(title: "Careful", message: "This is slow.")
        let session = SortSession(algorithm: FakeAlgorithm(confirmationWarning: warning), settings: makeFastSettings())

        await session.start(values: [3, 1, 2])
        session.declineWarning()

        #expect(session.gate == .declined)
        if case .idle = session.phase {} else {
            Issue.record("expected .idle after declining, got \(session.phase)")
        }

        // A timeout here (rather than a false positive) would mean declining didn't actually stop it.
        var didStayIdle = true
        for _ in 0..<20 {
            try await Task.sleep(for: .milliseconds(5))
            if case .idle = session.phase {} else {
                didStayIdle = false
                break
            }
        }
        #expect(didStayIdle)
    }
}
