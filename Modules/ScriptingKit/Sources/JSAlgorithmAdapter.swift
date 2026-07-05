import AlgorithmKit
import JavaScriptCore
import SortEngineKit

public enum ScriptExecutionError: Error, Equatable, CustomStringConvertible {
    case scriptFailed(String)

    public var description: String {
        switch self {
        case let .scriptFailed(message): "Script failed: \(message)"
        }
    }
}

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

    @discardableResult
    public func recordThrowing(into engine: inout RecordingEngine, timeout: TimeInterval = 5.0) throws -> RecordingEngine {
        let bridge = JSRecordingEngineBridge(engine: engine)
        guard let context = JSContext() else {
            throw ScriptExecutionError.scriptFailed("Failed to create JSContext")
        }
        context.setObject(bridge, forKeyedSubscript: "engine" as NSString)

        var caughtError: String?
        context.exceptionHandler = { _, exception in
            caughtError = exception?.toString()
        }

        // A hard wall-clock ceiling on untrusted script execution — a badly written or malicious
        // plugin cannot hang the app.
        installExecutionTimeLimit(on: context, seconds: timeout)

        context.evaluateScript(source)
        context.evaluateScript("sort(engine)")

        engine = bridge.engine

        if let caughtError {
            throw ScriptExecutionError.scriptFailed(caughtError)
        }
        return engine
    }
}
