import JavaScriptCore

/// `JSContextGroupSetExecutionTimeLimit` is part of JavaScriptCore's private API
/// (`JSContextRefPrivate.h`) — not in the public umbrella header Swift sees when it imports the
/// framework, but the symbol is exported by the framework binary at runtime. Binding to it by
/// name via `@_silgen_name` reaches it without a bridging header, keeping all the C interop the
/// module needs isolated to this one file.
@_silgen_name("JSContextGroupSetExecutionTimeLimit")
private func jsContextGroupSetExecutionTimeLimit(
    _ group: JSContextGroupRef,
    _ limit: Double,
    _ callback: (@convention(c) (JSContextRef?, UnsafeMutableRawPointer?) -> Bool)?,
    _ context: UnsafeMutableRawPointer?
)

/// Enforces a hard wall-clock ceiling on untrusted script execution — a badly written or
/// malicious plugin cannot hang the app. When the limit is hit, JavaScriptCore's watchdog raises a
/// termination exception inside the running script, which surfaces through the context's
/// `exceptionHandler` exactly like any other JS exception.
func installExecutionTimeLimit(on context: JSContext, seconds: TimeInterval) {
    guard let group = JSContextGetGroup(context.jsGlobalContextRef) else { return }
    jsContextGroupSetExecutionTimeLimit(group, seconds, { _, _ in true }, nil)
}
