import AlgorithmKit
import Charts
import SortEngineKit
import SwiftUI

/// Batch-records `algorithm` at several array sizes spanning its `sizeRange`, entirely off-screen
/// — `RecordingEngine` only, never `ReplayEngine` (§1 of ARCHITECTURE_V2.md: `recordingDuration`
/// is the real algorithmic performance number precisely because nothing paces or draws it). This
/// is what turns that already-recorded number into the Swift Charts complexity view `TODO.md`
/// asked for, rather than a debug-console print.
struct ComplexityChart: View {
    let algorithm: any SortAlgorithm

    private struct DataPoint: Identifiable {
        let size: Int
        let averageRecordingDuration: TimeInterval
        let averageCompareCount: Double
        var id: Int { size }
    }

    @State private var dataPoints: [DataPoint] = []
    @State private var isBenchmarking = false

    /// Multiple trials per size, averaged — a single shuffle can land on an unrepresentative
    /// permutation (best/worst case), especially for anything comparison-count-sensitive.
    // nonisolated: read from `benchmark(algorithm:size:)`, itself nonisolated so it can run inside
    // `Task.detached` — safe since it's an immutable Sendable Int, not actual mutable shared state.
    private nonisolated static let trialsPerSize = 5
    private static let sampleSizeCount = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isBenchmarking {
                ProgressView("Benchmarking \(algorithm.metadata.displayName)…")
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else if dataPoints.isEmpty {
                ContentUnavailableView("No Benchmark Yet", systemImage: "chart.xyaxis.line")
                    .frame(minHeight: 160)
            } else {
                Text("Comparisons vs. Array Size")
                    .font(.subheadline.bold())
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Size", point.size),
                        y: .value("Comparisons", point.averageCompareCount)
                    )
                    PointMark(
                        x: .value("Size", point.size),
                        y: .value("Comparisons", point.averageCompareCount)
                    )
                }
                .frame(height: 160)

                Text("Recording Time vs. Array Size")
                    .font(.subheadline.bold())
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Size", point.size),
                        y: .value("Milliseconds", point.averageRecordingDuration * 1000)
                    )
                    PointMark(
                        x: .value("Size", point.size),
                        y: .value("Milliseconds", point.averageRecordingDuration * 1000)
                    )
                }
                .frame(height: 160)
            }

            Button(dataPoints.isEmpty ? "Run Benchmark" : "Re-run Benchmark") {
                Task { await runBenchmark() }
            }
            .disabled(isBenchmarking)
            .accessibilityIdentifier("runBenchmarkButton")
        }
        .task(id: algorithm.id) {
            dataPoints = []
            await runBenchmark()
        }
    }

    private func runBenchmark() async {
        isBenchmarking = true
        let algorithm = self.algorithm
        let sizes = Self.sampleSizes(for: algorithm.metadata.sizeRange)
        let points = await Task.detached(priority: .userInitiated) {
            sizes.map { size in Self.benchmark(algorithm: algorithm, size: size) }
        }.value
        dataPoints = points
        isBenchmarking = false
    }

    private nonisolated static func benchmark(algorithm: any SortAlgorithm, size: Int) -> DataPoint {
        var totalDuration: TimeInterval = 0
        var totalCompareCount = 0
        for _ in 0..<trialsPerSize {
            var engine = RecordingEngine(values: Array(1...size).shuffled())
            let start = Date()
            algorithm.record(into: &engine)
            totalDuration += Date().timeIntervalSince(start)
            totalCompareCount += engine.finish().compareCount
        }
        return DataPoint(
            size: size,
            averageRecordingDuration: totalDuration / Double(trialsPerSize),
            averageCompareCount: Double(totalCompareCount) / Double(trialsPerSize)
        )
    }

    /// `sampleSizeCount` sizes evenly spaced across the algorithm's own allowed range — every
    /// algorithm gets a chart shaped by what it actually supports, not a hardcoded size list that
    /// might fall outside a narrow-range algorithm's `sizeRange` (e.g. Bogo Sort's `4...16`).
    static func sampleSizes(for range: ClosedRange<Int>) -> [Int] {
        guard range.upperBound > range.lowerBound else { return [range.lowerBound] }
        let step = max(1, (range.upperBound - range.lowerBound) / (sampleSizeCount - 1))
        var sizes = Array(Swift.stride(from: range.lowerBound, through: range.upperBound, by: step))
        if sizes.last != range.upperBound { sizes.append(range.upperBound) }
        return sizes
    }
}
