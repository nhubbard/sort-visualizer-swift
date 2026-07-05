import AlgorithmKit
import Foundation
import SortEngineKit

/// Native and scripted algorithms produce the exact same thing — a `Tape` — through the exact
/// same `RecordingEngine` primitive surface (§2.1). From the rest of the app's point of view there
/// is no difference between a native `SortAlgorithm` conformance and one of these.
public struct JSAlgorithmAdapter: SortAlgorithm {
    public let id: AlgorithmID
    public let metadata: AlgorithmMetadata
    /// Contents of the algorithm's `.js` file.
    public let source: String

    public init(id: AlgorithmID, metadata: AlgorithmMetadata, source: String) {
        self.id = id
        self.metadata = metadata
        self.source = source
    }

    /// `SortAlgorithm.record(into:)` can't throw (native algorithms never fail), so a caught
    /// script error is silently dropped here — leaving `engine`'s tape however far the script got
    /// before failing. Real error surfacing (`SortSession.phase = .failed(.pluginError(...))`)
    /// hangs off `recordThrowing(into:timeout:)` once `SortSession` exists (§3.5); until then, use
    /// that method directly to observe failures.
    public func record(into engine: inout RecordingEngine) {
        try? recordThrowing(into: &engine)
    }

    public func recordThrowing(into engine: inout RecordingEngine, timeout: TimeInterval = 5.0) throws {
        try runScript(source, entryPoint: "sort", into: &engine, timeout: timeout)
    }
}
