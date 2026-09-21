import Foundation

private typealias StartedCallback = @convention(c) (UnsafeMutableRawPointer?) -> Void
private typealias StopCallback = @convention(c) (UnsafeMutableRawPointer?) -> Int32

@_silgen_name("instruments_record_with_callbacks")
private func instruments_record_with_callbacks(
    _ pidOrDash: UnsafePointer<CChar>,
    _ executablePath: UnsafePointer<CChar>,
    _ outputPath: UnsafePointer<CChar>,
    _ templateName: UnsafePointer<CChar>,
    _ additionalIdentifiers: UnsafePointer<CChar>,
    _ configuredTemplatePath: UnsafePointer<CChar>,
    _ nativeOptionSpecifications: UnsafePointer<CChar>,
    _ durationSeconds: Double,
    _ callback: StartedCallback?,
    _ stopCallback: StopCallback?,
    _ context: UnsafeMutableRawPointer?
) -> Int32

@_silgen_name("instruments_prepare")
private func instruments_prepare() -> Int32

private final class StartCallbackBox {
    let action: (() -> Void)?
    let stopWhen: (() -> Bool)?
    init(action: (() -> Void)?, stopWhen: (() -> Bool)?) {
        self.action = action
        self.stopWhen = stopWhen
    }
}

private final class RecordingCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var requested = false

    func cancel() {
        lock.lock()
        requested = true
        lock.unlock()
    }

    var isRequested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return requested
    }
}

private let startTrampoline: StartedCallback = { context in
    guard let context else { return }
    Unmanaged<StartCallbackBox>.fromOpaque(context).takeUnretainedValue().action?()
}

private let stopTrampoline: StopCallback = { context in
    guard let context else { return 0 }
    return Unmanaged<StartCallbackBox>.fromOpaque(context)
        .takeUnretainedValue().stopWhen?() == true ? 1 : 0
}

/// An Instruments recording template installed with the selected Xcode.
///
/// Named cases participate in the Xcode 27 compatibility checks. Use
/// ``named(_:)`` only while investigating a template absent from this catalog;
/// it receives structural validation but has no recorded compatibility data.
public enum TraceTemplate: Sendable {
    case animationHitches, appLaunch, audioSystemTrace, cpuCounters, coreAI
    case dataPersistence, foundationModels, gameMemory, gamePerformance
    case gamePerformanceOverview, leaks, logging, metalSystemTrace, network
    case processorTrace, swiftConcurrency
    case swiftUI, systemTrace
    case cpuProfiler
    case allocations
    case timeProfiler
    case fileActivity
    case activityMonitor
    /// An installed template name that has not been added to the typed catalog.
    case named(String)

    var instrumentName: String {
        switch self {
        case .cpuProfiler: "CPU Profiler"
        case .allocations: "Allocations"
        case .timeProfiler: "Time Profiler"
        case .fileActivity: "File Activity"
        case .activityMonitor: "Activity Monitor"
        case .animationHitches: "Animation Hitches"
        case .appLaunch: "App Launch"
        case .audioSystemTrace: "Audio System Trace"
        case .cpuCounters: "CPU Counters"
        case .coreAI: "Core AI"
        case .dataPersistence: "Data Persistence"
        case .foundationModels: "Foundation Models"
        case .gameMemory: "Game Memory"
        case .gamePerformance: "Game Performance"
        case .gamePerformanceOverview: "Game Performance Overview"
        case .leaks: "Leaks"
        case .logging: "Logging"
        case .metalSystemTrace: "Metal System Trace"
        case .network: "Network"
        case .processorTrace: "Processor Trace"
        case .swiftConcurrency: "Swift Concurrency"
        case .swiftUI: "SwiftUI"
        case .systemTrace: "System Trace"
        case let .named(name): name
        }
    }
}

/// An instrument that can be composed with a recording template.
///
/// The raw value is the Xcode private registry identifier. ``TracePlan``
/// rejects duplicates, known platform exclusions, and incompatible additions
/// recorded in `MacCompatibility.generated.swift` before loading Instruments.
public enum TraceInstrument: String, Sendable, CaseIterable {
    case advancedGraphicsStatistics = "com.apple.dt.graphicsstatistics"
    case filesystemActivity = "com.apple.dt.instruments.fs-syscalls"
    case allocations = "com.apple.xray.instrument-type.oa"
    case cpuProfiler = "com.apple.xray.instrument-type.cpusampler"
    case hangs = "com.apple.dt-perfteam.hangs"
    case hitches = "com-apple-hitches"
    case pointsOfInterest = "com.apple.xray.instrument-type.poi"
    case timeProfiler = "com.apple.xray.instrument-type.coresampler2"
    case vmTracker = "com.apple.xray.instrument-type.vmtrack"
    case diskUsage = "com.apple.dt.instruments.diskusage"
    case diskIOLatency = "com.apple.dt.instruments.diskio-completion-time"
    case swiftTasks = "com.apple.dt.instrument.swift-concurrency-task"
    case swiftActors = "com.apple.dt.instrument.swift-concurrency-actor"
    case swiftExecutors = "com.apple.dt.instrument.swift-concurrency-execution-domain"
    case threadActivity = "com.apple.dt.instruments.thread-activity"
    case gcdPerformance = "com.apple.darwin.gcd.performance"
    case osLog = "com.apple.dt.os-log-instrument"
    case osSignpost = "com.apple.dt.os-log-signpost-instrument"
    case coreAnimationCommits = "com.apple.CoreAnimation.commit"

    var instrumentName: String {
        switch self {
        case .advancedGraphicsStatistics: "Advanced Graphics Statistics"
        case .filesystemActivity: "Filesystem Activity"
        case .allocations: "Allocations"
        case .cpuProfiler: "CPU Profiler"
        case .hangs: "Hangs"
        case .hitches: "Hitches"
        case .pointsOfInterest: "Points of Interest"
        case .timeProfiler: "Time Profiler"
        case .vmTracker: "VM Tracker"
        case .diskUsage: "Disk Usage"
        case .diskIOLatency: "Disk I/O Latency"
        case .swiftTasks: "Swift Tasks"
        case .swiftActors: "Swift Actors"
        case .swiftExecutors: "Swift Executors"
        case .threadActivity: "Thread Activity"
        case .gcdPerformance: "GCD Performance"
        case .osLog: "os_log"
        case .osSignpost: "os_signpost"
        case .coreAnimationCommits: "Core Animation Commits"
        }
    }
}

/// The process whose events a trace records.
public enum TraceTarget: Sendable {
    /// Launch an executable as a child of the private recorder.
    case launch(executable: URL)
    /// Attach to an existing process. The executable disambiguates the target
    /// for Instruments and must correspond to `pid`.
    case attach(pid: Int32, executable: URL)

    var pidArgument: String {
        switch self {
        case .launch: "-"
        case let .attach(pid, _): String(pid)
        }
    }

    var executable: URL {
        switch self {
        case let .launch(executable), let .attach(_, executable): executable
        }
    }
}

/// A `.trace` bundle destination used in a declarative ``TracePlan/build(_:)``.
public struct TraceOutput: Sendable {
    /// The local file URL at which Instruments will create the trace bundle.
    public let url: URL
    /// Creates an output directive for a local `.trace` URL.
    public init(_ url: URL) { self.url = url }
}

/// An element accepted by ``TracePlanBuilder``.
///
/// Most clients create directives implicitly by placing their associated
/// values in ``TracePlan/build(_:)`` rather than constructing this enum.
public enum TraceDirective: Sendable {
    case template(TraceTemplate)
    case target(TraceTarget)
    case duration(Duration)
    case output(TraceOutput)
    case instrument(TraceInstrument)
    case setting(TraceSetting)
}

/// A small result builder for one template, target, duration, and destination.
/// Duplicate or missing directives fail validation before Instruments starts.
@resultBuilder
public enum TracePlanBuilder {
    /// Converts a template expression into a plan directive.
    public static func buildExpression(_ value: TraceTemplate) -> [TraceDirective] { [.template(value)] }
    /// Converts a target expression into a plan directive.
    public static func buildExpression(_ value: TraceTarget) -> [TraceDirective] { [.target(value)] }
    /// Converts a duration expression into a plan directive.
    public static func buildExpression(_ value: Duration) -> [TraceDirective] { [.duration(value)] }
    /// Converts an output expression into a plan directive.
    public static func buildExpression(_ value: TraceOutput) -> [TraceDirective] { [.output(value)] }
    /// Converts an additional instrument expression into a plan directive.
    public static func buildExpression(_ value: TraceInstrument) -> [TraceDirective] { [.instrument(value)] }
    /// Converts a settings expression into a plan directive.
    public static func buildExpression(_ value: TraceSetting) -> [TraceDirective] { [.setting(value)] }
    /// Combines the directives in a builder block.
    public static func buildBlock(_ groups: [TraceDirective]...) -> [TraceDirective] { groups.flatMap { $0 } }
    /// Supports optional directives in a builder block.
    public static func buildOptional(_ directives: [TraceDirective]?) -> [TraceDirective] { directives ?? [] }
    /// Supports the first branch of conditional builder content.
    public static func buildEither(first directives: [TraceDirective]) -> [TraceDirective] { directives }
    /// Supports the second branch of conditional builder content.
    public static func buildEither(second directives: [TraceDirective]) -> [TraceDirective] { directives }
    /// Supports loops that emit directives.
    public static func buildArray(_ groups: [[TraceDirective]]) -> [TraceDirective] { groups.flatMap { $0 } }
}

/// A validated description of one Instruments recording.
///
/// Construct a plan with ``recording(_:of:for:savingTo:adding:settings:)`` or
/// ``build(_:)`` to validate it immediately. The memberwise initializer is
/// available for decoding and experiments; ``RecordingSession`` validates it
/// again before crossing into private frameworks.
public struct TracePlan: Sendable {
    /// The base Instruments template.
    public let template: TraceTemplate
    /// The process to launch or attach to.
    public let target: TraceTarget
    /// The maximum recording duration in seconds.
    public let durationSeconds: Double
    /// The local `.trace` bundle destination.
    public let outputURL: URL
    /// Instruments composed with the base template.
    public let additionalInstruments: [TraceInstrument]
    /// Option groups applied to the template or native instrument state.
    public let settings: [TraceSetting]

    /// Creates a plan. Call ``validate()`` before storing an unexecuted plan;
    /// ``RecordingSession`` also validates immediately before recording.
    public init(template: TraceTemplate, target: TraceTarget, durationSeconds: Double, outputURL: URL,
                additionalInstruments: [TraceInstrument] = [], settings: [TraceSetting] = []) {
        self.template = template
        self.target = target
        self.durationSeconds = durationSeconds
        self.outputURL = outputURL
        self.additionalInstruments = additionalInstruments
        self.settings = settings
    }

    /// A concise recipe for the common case. Validation happens before private APIs are called.
    public static func recording(
        _ template: TraceTemplate, of target: TraceTarget,
        for duration: Duration, savingTo outputURL: URL,
        adding additionalInstruments: [TraceInstrument] = [],
        settings: [TraceSetting] = []
    ) throws(RecordingError) -> TracePlan {
        let seconds = Double(duration.components.seconds)
            + Double(duration.components.attoseconds) / 1e18
        let plan = TracePlan(template: template, target: target,
                             durationSeconds: seconds, outputURL: outputURL,
                             additionalInstruments: additionalInstruments, settings: settings)
        try plan.validate()
        return plan
    }

    /// Example:
    /// ```swift
    /// let plan = try TracePlan.build {
    ///     TraceTemplate.timeProfiler
    ///     TraceTarget.attach(pid: processID, executable: executableURL)
    ///     Duration.seconds(2)
    ///     TraceOutput(outputURL)
    /// }
    /// ```
    public static func build(
        @TracePlanBuilder _ content: () -> [TraceDirective]
    ) throws(RecordingError) -> TracePlan {
        let directives = content()
        let templates = directives.compactMap { if case let .template(value) = $0 { value } else { nil } }
        let targets = directives.compactMap { if case let .target(value) = $0 { value } else { nil } }
        let durations = directives.compactMap { if case let .duration(value) = $0 { value } else { nil } }
        let outputs = directives.compactMap { if case let .output(value) = $0 { value } else { nil } }
        let instruments = directives.compactMap { if case let .instrument(value) = $0 { value } else { nil } }
        let settings = directives.compactMap { if case let .setting(value) = $0 { value } else { nil } }
        guard templates.count == 1, targets.count == 1, durations.count == 1, outputs.count == 1 else {
            throw .invalidPlan("A trace needs exactly one template, target, duration, and output")
        }
        return try recording(templates[0], of: targets[0], for: durations[0],
                             savingTo: outputs[0].url, adding: instruments, settings: settings)
    }

    /// Checks paths, duration, platform support, composition rules, and option
    /// bounds without starting Instruments.
    public func validate() throws(RecordingError) {
        guard durationSeconds.isFinite && durationSeconds > 0 && durationSeconds <= 3600 else {
            throw .invalidPlan("Duration must be between 0 and 3600 seconds")
        }
        guard target.executable.isFileURL && outputURL.isFileURL else {
            throw .invalidPlan("Target and output must be local file URLs")
        }
        guard outputURL.pathExtension == "trace" else {
            throw .invalidPlan("Output must have a .trace extension")
        }
        guard FileManager.default.fileExists(atPath: target.executable.path) else {
            throw .invalidPlan("Target executable does not exist")
        }
        if case let .attach(pid, _) = target, pid <= 0 {
            throw .invalidPlan("Attached process ID must be positive")
        }
        if case let .named(name) = template, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw .invalidPlan("Template name cannot be empty")
        }
        if MacCompatibility.unsupportedTemplates.contains(template.instrumentName) {
            throw .invalidPlan("\(template.instrumentName) is unsupported on macOS in this Xcode installation")
        }
        if template.instrumentName == "Processor Trace" {
            throw .invalidPlan("Processor Trace did not stop in the private recorder and its saved run was invalid")
        }
        guard Set(additionalInstruments.map(\.rawValue)).count == additionalInstruments.count else {
            throw .invalidPlan("An instrument may be added only once")
        }
        for left in additionalInstruments.indices {
            for right in additionalInstruments.indices where right > left {
                let pair = [additionalInstruments[left].rawValue,
                            additionalInstruments[right].rawValue].sorted().joined(separator: "|")
                if MacCompatibility.incompatibleInstrumentPairs.contains(pair) {
                    throw .invalidPlan("These two added instruments have a confirmed recording failure together in this Xcode")
                }
            }
        }
        if let unsupported = additionalInstruments.first(where: {
            MacCompatibility.unsupportedInstrumentIDs.contains($0.rawValue)
        }) {
            throw .invalidPlan("\(unsupported.rawValue) is unsupported on macOS")
        }
        if let existing = additionalInstruments.first(where: {
            MacCompatibility.templateInstrumentIDs[template.instrumentName]?.contains($0.rawValue) == true
        }) {
            throw .invalidPlan("\(template.instrumentName) already includes \(existing.instrumentName)")
        }
        if let incompatible = additionalInstruments.first(where: {
            MacCompatibility.incompatibleAdditions[template.instrumentName]?.contains($0.rawValue) == true
        }) {
            throw .invalidPlan("\(incompatible.instrumentName) has a known recording failure or excessive scratch use with \(template.instrumentName) in this Xcode")
        }
        let disablesWindow = settings.contains { setting in
            if case .captureLast(.disabled) = setting { return true }
            return false
        }
        if !disablesWindow, let incompatible = additionalInstruments.first(where: {
            MacCompatibility.windowedAdditions[template.instrumentName]?.contains($0.rawValue) == true
        }) {
            throw .invalidPlan("\(incompatible.instrumentName) does not support \(template.instrumentName)'s windowed recorder")
        }
        guard Set(settings.map(\.key)).count == settings.count else {
            throw .invalidPlan("Each settings group may appear only once")
        }
        for setting in settings {
            if case let .recordingMode(mode) = setting {
                if mode == .immediate && TemplateSettingsCatalog.immediateUnsupported.contains(template.instrumentName) {
                    throw .invalidPlan("\(template.instrumentName) does not support Immediate recording")
                }
            } else if case let .captureLast(capture) = setting {
                guard MacCompatibility.windowedTemplates.contains(template.instrumentName) else {
                    throw .invalidPlan("\(template.instrumentName) does not support Capture Last")
                }
                if case let .last(duration) = capture {
                    guard duration > .zero, duration <= .seconds(3600) else {
                        throw .invalidPlan("Capture Last duration must be between 0 and 3600 seconds")
                    }
                    if settings.contains(where: {
                        if case .recordingMode(.immediate) = $0 { return true }
                        return false
                    }) {
                        throw .invalidPlan("Capture Last requires Deferred recording")
                    }
                }
            } else if let groups = TemplateSettingsCatalog.groups[template.instrumentName], !groups.contains(setting.key) {
                let nativeInstrument: TraceInstrument? = switch setting.key {
                case "Hangs": .hangs
                case "Points of Interest": .pointsOfInterest
                case "Core Animation Commits": .coreAnimationCommits
                case "Allocations": .allocations
                case "os_log": .osLog
                case "os_signpost": .osSignpost
                default: nil
                }
                let isNativeAvailable = nativeInstrument.map { instrument in
                    additionalInstruments.contains(instrument)
                        || MacCompatibility.templateInstrumentIDs[template.instrumentName]?.contains(instrument.rawValue) == true
                } ?? false
                if !isNativeAvailable {
                    throw .invalidPlan("\(template.instrumentName) does not contain \(setting.key)")
                }
            }
            if case let .cpuCounters(options) = setting {
                if let value = options.pmiThreshold, value <= 0 { throw .invalidPlan("PMI threshold must be positive") }
                if let value = options.processBucketSize, value <= 0 { throw .invalidPlan("Process bucket size must be positive") }
            }
            if case let .allocations(options) = setting, let filters = options.recordedTypes {
                for filter in filters where filter.type.count > 256 || filter.type.contains(";") {
                    throw .invalidPlan("Allocation filter types must be at most 256 characters and cannot contain semicolons")
                }
            }
            if case let .osSignpost(_, subsystems) = setting {
                for subsystem in subsystems where subsystem.isEmpty || subsystem.count > 256
                    || subsystem.contains(";") {
                    throw .invalidPlan("Signpost subsystems must be 1...256 characters and cannot contain semicolons")
                }
            }
            if case let .coreAnimationCommits(options) = setting,
               !(0...2).contains(options.expensiveCommitSampling) {
                throw .invalidPlan("Core Animation Commits sampling must be 0, 1, or 2")
            }
            if case let .processorTrace(options) = setting {
                for value in [options.bufferSizeFill, options.bufferSizeWrap].compactMap({ $0 }) where !value.isFinite || value <= 0 {
                    throw .invalidPlan("Processor Trace buffer sizes must be positive and finite")
                }
            }
            if case let .leaks(mode) = setting, case let .automatic(interval) = mode {
                guard interval > .zero, interval <= .seconds(3600) else {
                    throw .invalidPlan("Leaks snapshot interval must be between 0 and 3600 seconds")
                }
            }
            if case let .vmTracker(options) = setting, let interval = options.snapshotInterval {
                guard interval > .zero, interval <= .seconds(3600) else {
                    throw .invalidPlan("VM snapshot interval must be between 0 and 3600 seconds")
                }
            }
        }
        guard !FileManager.default.fileExists(atPath: outputURL.path) else {
            throw .invalidPlan("Output trace already exists")
        }
    }
}

/// Stable failure categories returned by the Objective-C bridge.
///
/// Raw values are the bridge status codes and are suitable for diagnostics;
/// they are not Apple API error codes.
public enum RecordingFailure: Int32, Sendable {
    case invalidArguments = 2
    case templateNotFound = 3
    case templateLoadFailed = 4
    case startRejected = 5
    case saveFailed = 6
    case serviceHubUnavailable = 7
    case preflightTimedOut = 8
    case runIssues = 9
    case frameworkInitializationFailed = 10
    case instrumentUnavailable = 11
    case privateOptionRejected = 12
    case stopTimedOut = 14
    case targetUnsupported = 15
}

/// Errors produced while validating, preparing, or running a trace.
public enum RecordingError: Error, Sendable, CustomStringConvertible {
    /// The plan is internally inconsistent or unsupported by the recorded
    /// Xcode 27 compatibility data.
    case invalidPlan(String)
    /// The private bridge returned a recognized ``RecordingFailure``.
    case failed(RecordingFailure)
    /// The private bridge returned a status introduced after this wrapper.
    case unknownStatus(Int32)
    /// Swift task cancellation stopped recording and removed the partial trace.
    case cancelled

    /// A concise diagnostic suitable for logs and debug UI.
    public var description: String {
        switch self {
        case let .invalidPlan(message): message
        case let .failed(reason): "Instruments recording failed: \(reason)"
        case let .unknownStatus(status): "Instruments recording failed with unknown status \(status)"
        case .cancelled: "Instruments recording was cancelled"
        }
    }

    static func fromStatus(_ status: Int32) -> RecordingError {
        if let reason = RecordingFailure(rawValue: status) { return .failed(reason) }
        return .unknownStatus(status)
    }
}

/// Metadata returned after Instruments saves a trace successfully.
public struct RecordingResult: Sendable {
    /// The saved `.trace` bundle.
    public let traceURL: URL
    /// The template used by the recording.
    public let template: TraceTemplate
    /// The recorded process target.
    public let target: TraceTarget
    /// Wall-clock time spent in the private recording call, including setup
    /// and saving.
    public let elapsedTime: Duration
}

/// Progress emitted by ``RecordingSession/recordAsync(onEvent:stopWhen:)``.
public enum RecordingEvent: Sendable {
    /// Instruments has entered its running state and target work may begin.
    case started
    /// Instruments saved the trace and the async operation is about to return.
    case completed(RecordingResult)
}

/// One recording attempt. The async adapter uses a serial Dispatch queue so
/// it does not block Swift's cooperative executor or overlap private runs.
public final class RecordingSession: Sendable {
    private static let recordingQueue = DispatchQueue(label: "InstrumentsPrototype.Recorder", qos: .userInitiated)
    /// The immutable plan executed by this session.
    public let plan: TracePlan

    /// Creates a session. Recording validates the plan immediately before it
    /// crosses into private frameworks.
    public init(plan: TracePlan) {
        self.plan = plan
    }

    @discardableResult
    /// Performs a blocking recording and returns after the trace is saved.
    ///
    /// - Parameters:
    ///   - onStarted: Called on the recording thread after Instruments reports
    ///     `isRunning`. Start the operation being measured only after this call.
    ///   - stopWhen: Polled after recording starts. Return `true` to stop before
    ///     the plan's duration cap.
    /// - Returns: The saved `.trace` bundle URL.
    /// - Throws: ``RecordingError`` if validation, preflight, recording, or
    ///   saving fails.
    ///
    /// This method blocks its caller. Prefer ``recordAsync(onEvent:stopWhen:)``
    /// from asynchronous application code.
    public func record(
        onStarted: (() -> Void)? = nil, stopWhen: (() -> Bool)? = nil
    ) throws(RecordingError) -> URL {
        try plan.validate()

        let configuredTemplate: URL?
        if plan.settings.isEmpty { configuredTemplate = nil }
        else {
            let prepared = instruments_prepare()
            guard prepared == 0 else { throw RecordingError.fromStatus(prepared) }
            configuredTemplate = try TemplateArchivePatch.copy(template: plan.template, settings: plan.settings)
        }
        defer { if let configuredTemplate { try? FileManager.default.removeItem(at: configuredTemplate) } }
        let nativeOptions = TemplateArchivePatch.nativeOptionSpecifications(plan.settings)

        let callbackBox = onStarted == nil && stopWhen == nil
            ? nil : StartCallbackBox(action: onStarted, stopWhen: stopWhen)
        let status = withExtendedLifetime(callbackBox) {
            plan.target.pidArgument.withCString { pid in
                plan.target.executable.path.withCString { executable in
                    plan.outputURL.path.withCString { output in
                        plan.template.instrumentName.withCString { template in
                            plan.additionalInstruments.map(\.rawValue).joined(separator: ",").withCString { additions in
                                (configuredTemplate?.path ?? "").withCString { configuredPath in
                                    nativeOptions.withCString { nativeSettings in
                                        instruments_record_with_callbacks(
                                            pid, executable, output, template, additions,
                                            configuredPath, nativeSettings, plan.durationSeconds,
                                            onStarted == nil ? nil : startTrampoline,
                                            stopWhen == nil ? nil : stopTrampoline,
                                            callbackBox.map { Unmanaged.passUnretained($0).toOpaque() }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        guard status == 0 else { throw RecordingError.fromStatus(status) }
        return plan.outputURL
    }

    /// Schedules the blocking recorder on a serial Dispatch queue.
    ///
    /// - Parameters:
    ///   - onEvent: Receives start and completion events on the recorder's
    ///     serial Dispatch queue.
    ///   - stopWhen: Polled on that queue. Return `true` to request an early stop.
    /// - Returns: Metadata for the saved trace.
    /// - Throws: ``RecordingError/cancelled`` after task cancellation, or the
    ///   same typed failures as ``record(onStarted:stopWhen:)``.
    ///
    /// Framework
    /// initialization runs on the main actor first. Xcode 27 logs thread
    /// warnings for some package lookup calls on this queue, so treat this
    /// adapter as experimental and inspect the saved run before using it.
    /// `.started` fires only after the trace reports `isRunning == true`.
    /// The callback runs on the recorder's Dispatch queue. Cancellation asks
    /// the private recorder to stop at its next polling interval, then removes
    /// the partial output and throws `RecordingError.cancelled`. A preflight
    /// stuck inside Xcode's framework may still wait for its own timeout.
    public func recordAsync(
        onEvent: (@Sendable (RecordingEvent) -> Void)? = nil,
        stopWhen: (@Sendable () -> Bool)? = nil
    ) async throws(RecordingError) -> RecordingResult {
        if Task.isCancelled { throw .cancelled }
        let preparation = await MainActor.run { instruments_prepare() }
        guard preparation == 0 else { throw RecordingError.fromStatus(preparation) }
        let cancellation = RecordingCancellation()
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    Self.recordingQueue.async {
                        let start = ContinuousClock.now
                        do {
                            if cancellation.isRequested { throw RecordingError.cancelled }
                            let url = try self.record(onStarted: { onEvent?(.started) },
                                                      stopWhen: { cancellation.isRequested || stopWhen?() == true })
                            if cancellation.isRequested {
                                try? FileManager.default.removeItem(at: url)
                                throw RecordingError.cancelled
                            }
                            let result = RecordingResult(
                                traceURL: url, template: self.plan.template,
                                target: self.plan.target, elapsedTime: start.duration(to: .now))
                            onEvent?(.completed(result))
                            continuation.resume(returning: result)
                        } catch {
                            if cancellation.isRequested {
                                try? FileManager.default.removeItem(at: self.plan.outputURL)
                                continuation.resume(throwing: RecordingError.cancelled)
                            } else {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            } onCancel: {
                cancellation.cancel()
            }
        } catch let error as RecordingError {
            throw error
        } catch {
            throw .invalidPlan("Unexpected recording error: \(error)")
        }
    }
}

private final class AsyncEntryOutcome: @unchecked Sendable {
    private let lock = NSLock()
    private var storedStatus: Int32 = 1
    var status: Int32 { lock.withLock { storedStatus } }
    func setStatus(_ value: Int32) { lock.withLock { storedStatus = value } }
}

@_cdecl("instruments_swift_entry")
/// Entry point called by the injected C constructor.
///
/// This is public only so the C shim can resolve it from the Swift dynamic
/// library. Application clients should use ``RecordingSession`` instead.
public func instrumentsSwiftEntry() -> Int32 {
    let environment = ProcessInfo.processInfo.environment
    if let rawPort = environment["INSTRUMENTS_LISTEN_PORT"], let port = UInt16(rawPort) {
        return runTraceTriggerServer(port: port)
    }
    let executable = environment["INSTRUMENTS_TARGET_EXECUTABLE"] ?? "/bin/sleep"
    let output = environment["INSTRUMENTS_OUTPUT"] ?? "/private/tmp/injected-probe.trace"
    let templateName = environment["INSTRUMENTS_TEMPLATE"] ?? "CPU Profiler"
    let template: TraceTemplate = switch templateName {
    case "CPU Profiler": .cpuProfiler
    case "Allocations": .allocations
    case "Time Profiler": .timeProfiler
    case "File Activity": .fileActivity
    case "Activity Monitor": .activityMonitor
    default: .named(templateName)
    }
    let duration = Double(environment["INSTRUMENTS_DURATION"] ?? "2") ?? 2
    let exploratorySettings: [TraceSetting]
    if environment["INSTRUMENTS_IMMEDIATE"] == "1" {
        exploratorySettings = [.recordingMode(.immediate)]
    } else if environment["INSTRUMENTS_ALL_TIME_OPTIONS"] == "1" {
        exploratorySettings = [
            .timeProfiler(.init(highFrequencySampling: true, recordWaitingThreads: true,
                                recordKernelCallstacks: true, contextSwitchSampling: true)),
            .hangs(threshold: .milliseconds33, detectPriorityInversions: true),
            .pointsOfInterest(excludeOSLogs: true)
        ]
    } else if environment["INSTRUMENTS_ALL_CPU_OPTIONS"] == "1" {
        exploratorySettings = [
            .cpuProfiler(.init(highFrequencySampling: true, recordKernelCallstacks: true)),
            .hangs(threshold: .milliseconds33, detectPriorityInversions: true),
            .pointsOfInterest(excludeOSLogs: true)
        ]
    } else if let seconds = environment["INSTRUMENTS_VM_SECONDS"].flatMap(Double.init) {
        exploratorySettings = [.vmTracker(.init(snapshotInterval: .milliseconds(Int(seconds * 1000)),
                                                automaticSnapshots: true))]
    } else if environment["INSTRUMENTS_LEAK_MANUAL"] == "1" {
        exploratorySettings = [.leaks(.manual)]
    } else if let threshold = environment["INSTRUMENTS_CPU_PMI"].flatMap(Int.init) {
        exploratorySettings = [.cpuCounters(.init(pmiThreshold: threshold))]
    } else if environment["INSTRUMENTS_CPU_FLAGS"] == "1" {
        exploratorySettings = [.cpuCounters(.init(sampleByTime: false,
                                                  useDebuggingInformation: true,
                                                  useHighFrequencyForGuidedMode: true,
                                                  useHighFrequencyForManualMode: true))]
    } else if let seconds = environment["INSTRUMENTS_LEAK_SECONDS"].flatMap(Double.init) {
        exploratorySettings = [.leaks(.automatic(every: .milliseconds(Int(seconds * 1000))))]
    } else if environment["INSTRUMENTS_TIME_HIGH_FREQ"] == "1" {
        exploratorySettings = [.timeProfiler(.init(highFrequencySampling: true))]
    } else if environment["INSTRUMENTS_TIME_WAITING"] == "1" {
        exploratorySettings = [.timeProfiler(.init(recordWaitingThreads: true))]
    } else if environment["INSTRUMENTS_ADDED_HANGS"] == "1" {
        exploratorySettings = [.hangs(threshold: .milliseconds33)]
    } else if environment["INSTRUMENTS_DISABLE_WINDOW"] == "1" {
        exploratorySettings = [.captureLast(.disabled)]
    } else if let milliseconds = environment["INSTRUMENTS_CAPTURE_LAST_MS"].flatMap(Int.init) {
        exploratorySettings = [.captureLast(.last(.milliseconds(milliseconds)))]
    } else if let level = environment["INSTRUMENTS_CA_COMMIT_SAMPLING"].flatMap(Int.init) {
        exploratorySettings = [.coreAnimationCommits(.init(expensiveCommitSampling: level))]
    } else if environment["INSTRUMENTS_ALLOC_ZOMBIES"] == "1" {
        exploratorySettings = [.allocations(.init(enableNSZombieDetection: true))]
    } else if environment["INSTRUMENTS_ALLOC_FILTER"] == "1" {
        exploratorySettings = [.allocations(.init(recordedTypes: [
            .init(.record, matching: .contains, type: "Sort"),
            .init(.ignore, matching: .hasPrefix, type: "NS")
        ]))]
    } else if environment["INSTRUMENTS_METAL_SHADER_METRICS"] == "1" {
        exploratorySettings = [.metalPerformance(.init(shaderCompilationMetrics: true))]
    } else if environment["INSTRUMENTS_SWIFTUI_LAYOUT"] == "1" {
        exploratorySettings = [.swiftUI(enableLayoutTracing: true)]
    } else if environment["INSTRUMENTS_OSLOG_ALL"] == "1" {
        exploratorySettings = [.osLog(recordAllProcessesInSingleProcessMode: true)]
    } else if environment["INSTRUMENTS_OSSIGNPOST_ALL"] == "1" {
        exploratorySettings = [.osSignpost(recordAllProcessesInSingleProcessMode: true)]
    } else if environment["INSTRUMENTS_OSSIGNPOST_SUBSYSTEM"] == "1" {
        exploratorySettings = [.osSignpost(
            recordAllProcessesInSingleProcessMode: false,
            dynamicTracingEnabledSubsystems: ["com.nhubbard.InstrumentsPrototype"])]
    } else {
        exploratorySettings = []
    }
    let requestedAdditions = (environment["INSTRUMENTS_ADD_INSTRUMENTS"] ?? "")
        .split(separator: ",")
    let exploratoryAdditions = requestedAdditions.compactMap { TraceInstrument(rawValue: String($0)) }
    guard exploratoryAdditions.count == requestedAdditions.count else {
        FileHandle.standardError.write(Data("Unknown exploratory instrument identifier\n".utf8))
        return 2
    }
    let plan = TracePlan(
        template: template,
        target: .launch(executable: URL(fileURLWithPath: executable)),
        durationSeconds: duration,
        outputURL: URL(fileURLWithPath: output),
        additionalInstruments: exploratoryAdditions, settings: exploratorySettings
    )
    if environment["INSTRUMENTS_USE_ASYNC"] == "1" {
        let completion = DispatchSemaphore(value: 0)
        let outcome = AsyncEntryOutcome()
        let recordingTask = Task.detached {
            do {
                let result = try await RecordingSession(plan: plan).recordAsync { event in
                    if case .started = event {
                        FileHandle.standardError.write(Data("Async recording started\n".utf8))
                    }
                }
                FileHandle.standardError.write(Data("Async recording saved \(result.traceURL.path)\n".utf8))
                outcome.setStatus(0)
            } catch {
                FileHandle.standardError.write(Data("Async recording failed: \(error)\n".utf8))
            }
            completion.signal()
        }
        if let delay = environment["INSTRUMENTS_CANCEL_AFTER_MS"].flatMap(Int.init), delay >= 0 {
            Task.detached {
                try? await Task.sleep(for: .milliseconds(delay))
                recordingTask.cancel()
            }
        }
        // This entry runs from a dylib constructor on the main thread. Pump
        // that run loop while the async API performs its main-actor setup.
        while completion.wait(timeout: .now()) == .timedOut {
            _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
        return outcome.status
    }
    do {
        let saved = try RecordingSession(plan: plan).record()
        FileHandle.standardError.write(Data("Swift RecordingSession saved \(saved.path)\n".utf8))
        return 0
    } catch {
        FileHandle.standardError.write(Data("Swift RecordingSession error: \(error)\n".utf8))
        return 1
    }
}
