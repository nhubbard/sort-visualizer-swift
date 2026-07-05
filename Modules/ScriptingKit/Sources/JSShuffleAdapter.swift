import AlgorithmKit
import Foundation
import SortEngineKit

/// Shuffles are authored and discovered exactly like algorithms (`.js` + manifest) — a shuffle is
/// structurally just another `RecordingEngine`-driven algorithm (§2.1/§2A.4).
public struct JSShuffleAdapter: ShuffleAlgorithm {
    public let id: ShuffleID
    public let metadata: ShuffleMetadata
    /// Contents of the shuffle's `.js` file.
    public let source: String

    public init(id: ShuffleID, metadata: ShuffleMetadata, source: String) {
        self.id = id
        self.metadata = metadata
        self.source = source
    }

    /// Same story as `JSAlgorithmAdapter.record(into:)`: `ShuffleAlgorithm.record(into:)` can't
    /// throw, so a caught script error is silently dropped here — use `recordThrowing(into:timeout:)`
    /// directly to observe failures.
    public func record(into engine: inout RecordingEngine) {
        try? recordThrowing(into: &engine)
    }

    public func recordThrowing(into engine: inout RecordingEngine, timeout: TimeInterval = 5.0) throws {
        try runScript(source, entryPoint: "shuffle", into: &engine, timeout: timeout)
    }
}
