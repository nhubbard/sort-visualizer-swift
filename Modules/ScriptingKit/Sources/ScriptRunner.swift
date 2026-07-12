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

/// Shared by `JSAlgorithmAdapter` and `JSShuffleAdapter` — both are "run this script's entry point
/// function against a `RecordingEngine`," differing only in what that function is named
/// (`sort`/`shuffle`) and which protocol wraps the result. Native and scripted algorithms/shuffles
/// produce the exact same thing — a `Tape` — through this exact `RecordingEngine` primitive
/// surface (§2.1).
func runScript(_ source: String, entryPoint: String, into engine: inout RecordingEngine, timeout: TimeInterval) throws {
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
    context.evaluateScript("\(entryPoint)(engine)")

    engine = bridge.engine

    if let caughtError {
        throw ScriptExecutionError.scriptFailed(caughtError)
    }
}
