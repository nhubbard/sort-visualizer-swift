import AlgorithmKit
import Foundation
import Metal
import Testing
@testable import SortEngineKit
@testable import SortFeature

/// Permanent regression coverage, not a throwaway diagnostic (despite the filename, kept for now)
/// — written while investigating a user report of a stale-looking block of bars on the right edge
/// of a Counting Sort + Rainbow (Metal) run at n=256. These tests proved the GPU INSTANCE BUFFER
/// itself ends up fully correct after a complete playback, even across a mid-playback resize —
/// ruling out "some write got lost" and "a resize corrupts prior writes" as the cause. The actual
/// bug turned out to be in `MetalRendererView`'s on-screen PRESENTATION timing (a stale displayed
/// frame, not stale buffer contents — see the forced completion redraw in
/// `MetalRendererView.Coordinator.setUp`), which these buffer-level tests can't exercise (no live
/// `MTKView`/display refresh cadence in a headless test target) — but they're worth keeping as a
/// standing guarantee that the buffer-write half of the pipeline stays correct.
///
/// `FakeCountingSort` duplicates `BuiltInAlgorithms.CountingSort.record(into:)` verbatim rather
/// than depending on that module — `SortFeature`'s test target doesn't currently depend on
/// `BuiltInAlgorithms` (see `Project.swift`), same reason `SortSessionTests.FakeAlgorithm`
/// duplicates a bubble sort instead of importing one.
private struct FakeCountingSort: SortAlgorithm {
    let id = AlgorithmID(rawValue: "fake-countingsort")
    let metadata = AlgorithmMetadata(
        displayName: "Fake Counting Sort", category: .distribution, sizeRange: 16...256, stable: true,
        timeComplexity: ComplexityBounds(best: "O(n+k)", average: "O(n+k)", worst: "O(n+k)"),
        spaceComplexity: "O(n+k)", iconName: "fake"
    )

    func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }

        var maxValue = engine.values[0]
        for i in 1..<n where engine.values[i] > maxValue {
            maxValue = engine.values[i]
        }

        var values = [Int]()
        values.reserveCapacity(n)
        for i in 0..<n {
            values.append(engine.values[i])
        }

        var counts = [Int](repeating: 0, count: maxValue + 1)
        for value in values {
            counts[value] += 1
        }
        for i in 1..<counts.count {
            counts[i] += counts[i - 1]
        }

        let outputHandle = engine.createAuxArray(length: n)
        var output = [Int](repeating: 0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            let value = values[i]
            counts[value] -= 1
            output[counts[value]] = value
            engine.writeAux(outputHandle, at: counts[value], value: value)
        }

        for i in 0..<n {
            engine.setValue(i, output[i])
        }

        engine.deleteAuxArray(outputHandle)
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

@Suite
struct MetalShapeRendererBufferConsistencyTests {
    @MainActor
    @Test
    func rainbowMetalBufferMatchesFinalSortedValuesAtN256() async throws {
        let size = 256
        let tape = SortSession.makeTape(algorithm: FakeCountingSort(), shuffle: FakeReverseShuffle(), size: size)
        let replay = ReplayEngine(tape: tape)

        let device = try #require(MTLCreateSystemDefaultDevice())
        let renderer = try #require(MetalShapeRenderer<RainbowMetalLayout>(device: device))
        let canvasSize = CGSize(width: 1920, height: 1080)

        // Mirrors `MetalRendererView.Coordinator.setUp`/`reconcile(pixelSize:)` exactly: an initial
        // full `reset` from the current frame, then per-operation incremental `apply` from
        // `onOperationApplied` for the rest of playback.
        func valueRange(for values: [Int]) -> ClosedRange<Int> {
            guard let minValue = values.min(), let maxValue = values.max(), minValue < maxValue else { return 0...1 }
            return minValue...maxValue
        }
        func markers(for frame: [ReplayEngine.BarState]) -> [Int: Set<Int>] {
            Dictionary(uniqueKeysWithValues: frame.enumerated().map { ($0.offset, $0.element.markers) })
        }

        renderer.reset(
            values: replay.frame.map(\.value), valueRange: valueRange(for: replay.frame.map(\.value)),
            markers: markers(for: replay.frame), canvasSize: canvasSize, scale: 1
        )
        replay.onOperationApplied = { operation in
            let values = replay.frame.map(\.value)
            renderer.apply(operation, values: values, valueRange: valueRange(for: values), markers: markers(for: replay.frame))
        }

        replay.speed = 100_000
        replay.play()
        let deadline = ContinuousClock.now + .seconds(10)
        while replay.stepIndex < replay.totalOperationCount, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }

        let finalValues = replay.frame.map(\.value)
        #expect(finalValues == Array(1...size), "sanity: the DATA must be correctly sorted")

        let instances = renderer.debugInstances()
        #expect(instances.count == size)

        var mismatches: [(index: Int, expectedHeight: Float, actualHeight: Float)] = []
        for index in 0..<size {
            let normalized = Float(finalValues[index] - 1) / Float(size - 1)
            let expectedHeight = Float(canvasSize.height) * normalized
            let actualHeight = instances[index].size.y
            if abs(expectedHeight - actualHeight) > 1.0 {
                mismatches.append((index, expectedHeight, actualHeight))
            }
        }

        if !mismatches.isEmpty {
            print("DIAGNOSTIC \(mismatches.count) mismatched slots out of \(size):")
            for mismatch in mismatches.prefix(20) {
                print(
                    "  index=\(mismatch.index) expectedHeight=\(mismatch.expectedHeight) "
                        + "actualHeight=\(mismatch.actualHeight)"
                )
            }
        }
        #expect(mismatches.isEmpty, "\(mismatches.count) slot(s) never got the correct final height written")
    }

    /// Same setup, but simulates exactly what the sidebar toggle does live: a resize (a second
    /// `reset()` at a different canvas size, matching `MetalRendererView.Coordinator.reconcile`'s
    /// own behavior when `onDrawableSizeChange` fires) landing PARTWAY through playback, not
    /// before it starts. `ManualTickDriver` drives this deterministically instead of racing a real
    /// display link to land a resize at a precise, reproducible point mid-tape.
    @MainActor
    @Test
    func rainbowMetalBufferStaysCorrectAfterMidPlaybackResize() async throws {
        let size = 256
        let tape = SortSession.makeTape(algorithm: FakeCountingSort(), shuffle: FakeReverseShuffle(), size: size)
        let driver = ManualTickDriver()
        let replay = ReplayEngine(tape: tape, displayLinkFactory: { driver })

        let device = try #require(MTLCreateSystemDefaultDevice())
        let renderer = try #require(MetalShapeRenderer<RainbowMetalLayout>(device: device))
        var canvasSize = CGSize(width: 1920, height: 1080)

        func valueRange(for values: [Int]) -> ClosedRange<Int> {
            guard let minValue = values.min(), let maxValue = values.max(), minValue < maxValue else { return 0...1 }
            return minValue...maxValue
        }
        func markers(for frame: [ReplayEngine.BarState]) -> [Int: Set<Int>] {
            Dictionary(uniqueKeysWithValues: frame.enumerated().map { ($0.offset, $0.element.markers) })
        }
        func fullReset() {
            renderer.reset(
                values: replay.frame.map(\.value), valueRange: valueRange(for: replay.frame.map(\.value)),
                markers: markers(for: replay.frame), canvasSize: canvasSize, scale: 1
            )
        }

        fullReset()
        replay.onOperationApplied = { operation in
            let values = replay.frame.map(\.value)
            renderer.apply(operation, values: values, valueRange: valueRange(for: values), markers: markers(for: replay.frame))
        }

        replay.speed = 20.0 // slow enough that a clamped 0.25s tick doesn't finish the whole tape at once
        replay.play()
        driver.fireTick(elapsed: 0)
        driver.fireTick(elapsed: 1.0) // clamped to 0.25s * 20 ops/sec = 5 ops
        try await Task.sleep(for: .milliseconds(20))
        #expect(replay.stepIndex > 0)
        #expect(replay.stepIndex < replay.totalOperationCount, "test setup: must still be mid-tape here")

        // The resize: a genuinely different size, mimicking the sidebar toggling.
        canvasSize = CGSize(width: 1400, height: 900)
        fullReset()

        replay.speed = 100_000
        driver.fireTick(elapsed: 1.0) // finish the rest of the tape
        let deadline = ContinuousClock.now + .seconds(10)
        while replay.stepIndex < replay.totalOperationCount, ContinuousClock.now < deadline {
            driver.fireTick(elapsed: 1.0)
            try await Task.sleep(for: .milliseconds(5))
        }

        let finalValues = replay.frame.map(\.value)
        #expect(finalValues == Array(1...size), "sanity: the DATA must be correctly sorted")

        let instances = renderer.debugInstances()
        #expect(instances.count == size)

        var mismatches: [(index: Int, expectedHeight: Float, actualHeight: Float)] = []
        for index in 0..<size {
            let normalized = Float(finalValues[index] - 1) / Float(size - 1)
            let expectedHeight = Float(canvasSize.height) * normalized
            let actualHeight = instances[index].size.y
            if abs(expectedHeight - actualHeight) > 1.0 {
                mismatches.append((index, expectedHeight, actualHeight))
            }
        }

        if !mismatches.isEmpty {
            print("DIAGNOSTIC (post-resize) \(mismatches.count) mismatched slots out of \(size):")
            for mismatch in mismatches.prefix(20) {
                print(
                    "  index=\(mismatch.index) expectedHeight=\(mismatch.expectedHeight) "
                        + "actualHeight=\(mismatch.actualHeight)"
                )
            }
        }
        #expect(mismatches.isEmpty, "\(mismatches.count) slot(s) never got the correct final height written")
    }
}

/// Duplicated from `SortSessionTests.ManualTickDriver` — test targets can't import each other's
/// test code.
private final class ManualTickDriver: DisplayLinkDriving {
    private var onTick: ((TimeInterval) -> Void)?

    func start(onTick: @escaping (TimeInterval) -> Void) {
        self.onTick = onTick
    }

    func stop() {
        onTick = nil
    }

    func fireTick(elapsed: TimeInterval) {
        onTick?(elapsed)
    }
}
