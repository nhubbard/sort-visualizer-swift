import Foundation

/// Handle for one of an algorithm's scratch buffers (merge sort's temp array, bucket sort's
/// buckets, LSD Radix's digit registers). Only ever produced by `RecordingEngine.createAuxArray`.
public struct AuxHandle: Hashable, Sendable, Codable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct TapeHeader: Sendable, Codable, Equatable {
    public let algorithmID: String
    public let initialValues: [Int]
    /// Seeds e.g. Radix's shuffled bucket→color map, deterministically.
    public let visualSeed: UInt64
    public let compareCount: Int
    public let swapCount: Int
    /// Wall-clock time to RECORD — this is the real perf number, decoupled from playback speed.
    public let recordingDuration: TimeInterval
    public let recordedAt: Date

    public init(
        algorithmID: String,
        initialValues: [Int],
        visualSeed: UInt64,
        compareCount: Int,
        swapCount: Int,
        recordingDuration: TimeInterval,
        recordedAt: Date
    ) {
        self.algorithmID = algorithmID
        self.initialValues = initialValues
        self.visualSeed = visualSeed
        self.compareCount = compareCount
        self.swapCount = swapCount
        self.recordingDuration = recordingDuration
        self.recordedAt = recordedAt
    }
}

public struct Tape: Sendable, Codable, Equatable {
    public let header: TapeHeader
    public let operations: [SortOperation]

    public init(header: TapeHeader, operations: [SortOperation]) {
        self.header = header
        self.operations = operations
    }
}
