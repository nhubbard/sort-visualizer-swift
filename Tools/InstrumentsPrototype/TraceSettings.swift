import Foundation

@_silgen_name("instruments_template_path")
private func instrumentsTemplatePath(_ name: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

/// Only modes confirmed by both the template archive and saved traces.
public enum TraceRecordingMode: Sendable {
    /// Streams instrument data directly to the trace store.
    case immediate
    /// Buffers data according to the template's deferred recording policy.
    case deferred
}

/// `.disabled` retains the full run; `.last` keeps only its final interval.
public enum CaptureLast: Sendable {
    /// Keeps the complete recording.
    case disabled
    /// Keeps only the final positive duration when recording stops.
    case last(Duration)
}

/// The duration at which the Hangs instrument begins reporting a stall.
public enum HangThreshold: Int, Sendable {
    case milliseconds500 = 0
    case milliseconds250 = 1
    case milliseconds100 = 2
    case milliseconds33 = 3
}

/// Options for the Time Profiler instrument.
///
/// A `nil` property preserves the installed template's value. This convention
/// applies to every optional property in the settings structures below.
public struct TimeProfilerSettings: Sendable {
    /// Uses the template's high-frequency sampling interval.
    public var highFrequencySampling: Bool?
    /// Includes samples from waiting as well as running threads.
    public var recordWaitingThreads: Bool?
    /// Captures kernel frames when the host permits kernel call stacks.
    public var recordKernelCallstacks: Bool?
    /// Enables context-switch based sampling.
    public var contextSwitchSampling: Bool?
    /// Creates a partial Time Profiler override. `nil` values are unchanged.
    public init(highFrequencySampling: Bool? = nil, recordWaitingThreads: Bool? = nil,
                recordKernelCallstacks: Bool? = nil, contextSwitchSampling: Bool? = nil) {
        self.highFrequencySampling = highFrequencySampling
        self.recordWaitingThreads = recordWaitingThreads
        self.recordKernelCallstacks = recordKernelCallstacks
        self.contextSwitchSampling = contextSwitchSampling
    }
}

/// Options for the CPU Profiler instrument.
public struct CPUProfilerSettings: Sendable {
    /// Uses the template's high-frequency sampling interval.
    public var highFrequencySampling: Bool?
    /// Captures kernel frames when the host permits kernel call stacks.
    public var recordKernelCallstacks: Bool?
    /// Creates a partial CPU Profiler override. `nil` values are unchanged.
    public init(highFrequencySampling: Bool? = nil, recordKernelCallstacks: Bool? = nil) {
        self.highFrequencySampling = highFrequencySampling
        self.recordKernelCallstacks = recordKernelCallstacks
    }
}

/// Decoder-verified options for the CPU Counters instrument.
public struct CPUCounterSettings: Sendable {
    /// The positive performance-monitor interrupt event threshold.
    public var pmiThreshold: Int?
    /// The positive number of samples grouped into a process bucket.
    public var processBucketSize: Int?
    /// Selects time sampling instead of event-threshold sampling.
    public var sampleByTime: Bool?
    /// Uses symbol and debugging information when resolving counter samples.
    public var useDebuggingInformation: Bool?
    /// Enables the high-frequency preset for guided configuration.
    public var useHighFrequencyForGuidedMode: Bool?
    /// Enables the high-frequency preset for manual configuration.
    public var useHighFrequencyForManualMode: Bool?
    /// Creates a partial CPU Counters override. `nil` values are unchanged.
    public init(pmiThreshold: Int? = nil, processBucketSize: Int? = nil,
                sampleByTime: Bool? = nil, useDebuggingInformation: Bool? = nil,
                useHighFrequencyForGuidedMode: Bool? = nil,
                useHighFrequencyForManualMode: Bool? = nil) {
        self.pmiThreshold = pmiThreshold
        self.processBucketSize = processBucketSize
        self.sampleByTime = sampleByTime
        self.useDebuggingInformation = useDebuggingInformation
        self.useHighFrequencyForGuidedMode = useHighFrequencyForGuidedMode
        self.useHighFrequencyForManualMode = useHighFrequencyForManualMode
    }
}

/// Options for the Allocations instrument.
public struct AllocationSettings: Sendable {
    /// Discards allocation events after their memory has been freed.
    public var discardEventsForFreedMemory: Bool?
    /// Discards data excluded by recording filters when the trace stops.
    public var discardUnrecordedDataUponStop: Bool?
    /// Enables zombie detection for Objective-C objects.
    public var enableNSZombieDetection: Bool?
    /// Attempts to identify virtual C++ object types.
    public var identifyVirtualCppObjects: Bool?
    /// Records virtual-memory allocations without ordinary heap allocations.
    public var onlyTrackVMAllocations: Bool?
    /// Records retain and release events used for reference-count histories.
    public var recordReferenceCounts: Bool?
    /// Ordered type-name filters applied by Allocations.
    public var recordedTypes: [AllocationTypeFilter]?
    /// Creates a partial Allocations override. `nil` values are unchanged.
    public init(discardEventsForFreedMemory: Bool? = nil,
                discardUnrecordedDataUponStop: Bool? = nil,
                enableNSZombieDetection: Bool? = nil,
                identifyVirtualCppObjects: Bool? = nil,
                onlyTrackVMAllocations: Bool? = nil,
                recordReferenceCounts: Bool? = nil,
                recordedTypes: [AllocationTypeFilter]? = nil) {
        self.discardEventsForFreedMemory = discardEventsForFreedMemory
        self.discardUnrecordedDataUponStop = discardUnrecordedDataUponStop
        self.enableNSZombieDetection = enableNSZombieDetection
        self.identifyVirtualCppObjects = identifyVirtualCppObjects
        self.onlyTrackVMAllocations = onlyTrackVMAllocations
        self.recordReferenceCounts = recordReferenceCounts
        self.recordedTypes = recordedTypes
    }
}

/// Whether a matching allocation type is included or excluded.
public enum AllocationFilterAction: String, Sendable { case record, ignore }
/// The supported comparison between a runtime type name and a filter string.
public enum AllocationFilterMatch: String, Sendable { case contains, hasPrefix }

/// One decoder-verified Allocations type filter. Rules are evaluated in order.
public struct AllocationTypeFilter: Sendable {
    /// Includes or excludes matching types.
    public var action: AllocationFilterAction
    /// The string comparison performed against a runtime type name.
    public var match: AllocationFilterMatch
    /// The case-sensitive type-name fragment or prefix.
    public var type: String
    /// Whether Instruments evaluates this rule.
    public var enabled: Bool
    /// Creates one ordered allocation type rule.
    public init(_ action: AllocationFilterAction, matching match: AllocationFilterMatch,
                type: String, enabled: Bool = true) {
        self.action = action
        self.match = match
        self.type = type
        self.enabled = enabled
    }
}

/// Options for Metal Performance Overview.
public struct MetalPerformanceSettings: Sendable {
    /// Collects metrics grouped by rendered frame.
    public var perFrameMetrics: Bool?
    /// Collects shader compilation metrics.
    public var shaderCompilationMetrics: Bool?
    /// Creates a partial Metal Performance override.
    public init(perFrameMetrics: Bool? = nil, shaderCompilationMetrics: Bool? = nil) {
        self.perFrameMetrics = perFrameMetrics
        self.shaderCompilationMetrics = shaderCompilationMetrics
    }
}

/// Sampling level accepted by Core Animation Commits in this Xcode build.
/// The decoder accepts 0, 1, and 2; the meaning of each level is private.
public struct CoreAnimationCommitSettings: Sendable {
    /// The private decoder's sampling level in the closed range `0...2`.
    public var expensiveCommitSampling: Int
    /// Creates a validated Core Animation commit sampling override.
    public init(expensiveCommitSampling: Int) {
        self.expensiveCommitSampling = expensiveCommitSampling
    }
}

/// Experimental Processor Trace buffer controls.
///
/// Processor Trace is rejected by ``TracePlan`` because its private stop
/// lifecycle did not produce a valid export in this Xcode build. These fields
/// remain typed for continued investigation.
public struct ProcessorTraceSettings: Sendable {
    /// Positive fill-mode buffer size in the private option's native units.
    public var bufferSizeFill: Double?
    /// Positive wrapping buffer size in the private option's native units.
    public var bufferSizeWrap: Double?
    /// Requests throttling intended to prevent trace-data loss.
    public var preventDataLoss: Bool?
    /// Creates a partial experimental Processor Trace override.
    public init(bufferSizeFill: Double? = nil, bufferSizeWrap: Double? = nil,
                preventDataLoss: Bool? = nil) {
        self.bufferSizeFill = bufferSizeFill
        self.bufferSizeWrap = bufferSizeWrap
        self.preventDataLoss = preventDataLoss
    }
}

/// Controls when the Leaks instrument performs heap snapshots.
public enum LeakSnapshots: Sendable {
    /// Snapshots occur only when requested by the recorder UI or private API.
    case manual
    /// Instruments automatically snapshots at the specified positive interval.
    case automatic(every: Duration)
}

/// Options for the VM Tracker instrument.
public struct VMTrackerSettings: Sendable {
    /// The positive interval between automatic VM snapshots.
    public var snapshotInterval: Duration?
    /// Enables periodic snapshots.
    public var automaticSnapshots: Bool?
    /// Creates a partial VM Tracker override.
    public init(snapshotInterval: Duration? = nil, automaticSnapshots: Bool? = nil) {
        self.snapshotInterval = snapshotInterval
        self.automaticSnapshots = automaticSnapshots
    }
}

/// Typed settings are attached to a plan and checked against its template.
/// Omitted fields retain the installed template's defaults.
public enum TraceSetting: Sendable {
    /// Sets the command-wide immediate or deferred recording mode.
    case recordingMode(TraceRecordingMode)
    /// Configures a windowed template's retained interval.
    case captureLast(CaptureLast)
    /// Overrides Time Profiler options present in the template.
    case timeProfiler(TimeProfilerSettings)
    /// Overrides CPU Profiler options present in the template.
    case cpuProfiler(CPUProfilerSettings)
    /// Configures the Hangs instrument and optional priority inversion checks.
    case hangs(threshold: HangThreshold, detectPriorityInversions: Bool = false)
    /// Controls whether Points of Interest excludes ordinary OS log messages.
    case pointsOfInterest(excludeOSLogs: Bool)
    /// Overrides CPU Counters options present in the template.
    case cpuCounters(CPUCounterSettings)
    /// Configures an Allocations instrument in the template or additions.
    case allocations(AllocationSettings)
    /// Configures Metal Performance Overview.
    case metalPerformance(MetalPerformanceSettings)
    /// Enables or disables SwiftUI layout tracing.
    case swiftUI(enableLayoutTracing: Bool)
    /// Controls whether Logging captures OS logs from every process.
    case osLog(recordAllProcessesInSingleProcessMode: Bool)
    /// Controls signpost process scope and dynamically enables subsystems.
    /// Construct signposters after recording starts so the logging system sees
    /// the newly enabled subsystem.
    case osSignpost(recordAllProcessesInSingleProcessMode: Bool,
                    dynamicTracingEnabledSubsystems: [String] = [])
    /// Configures Core Animation commit sampling.
    case coreAnimationCommits(CoreAnimationCommitSettings)
    /// Stores experimental Processor Trace options; recording is rejected.
    case processorTrace(ProcessorTraceSettings)
    /// Configures manual or periodic leak snapshots.
    case leaks(LeakSnapshots)
    /// Configures VM Tracker snapshots.
    case vmTracker(VMTrackerSettings)

    var key: String {
        switch self {
        case .recordingMode: "recordingMode"
        case .captureLast: "captureLast"
        case .timeProfiler: "Time Profiler"
        case .cpuProfiler: "CPU Profiler"
        case .hangs: "Hangs"
        case .pointsOfInterest: "Points of Interest"
        case .cpuCounters: "CPU Counters"
        case .allocations: "Allocations"
        case .metalPerformance: "Metal Performance Overview"
        case .swiftUI: "SwiftUI"
        case .osLog: "os_log"
        case .osSignpost: "os_signpost"
        case .coreAnimationCommits: "Core Animation Commits"
        case .processorTrace: "Processor Trace"
        case .leaks: "Leaks"
        case .vmTracker: "VM Tracker"
        }
    }
}

enum TemplateSettingsCatalog {
    // Captured from `xctrace --show-recording-options` on Xcode 27.
    static let groups: [String: Set<String>] = [
        "Activity Monitor": [], "Allocations": ["Allocations", "Points of Interest", "VM Tracker"],
        "Animation Hitches": ["Hangs", "Time Profiler"], "App Launch": ["Time Profiler"],
        "Audio System Trace": ["Hangs", "Points of Interest"],
        "CPU Counters": ["CPU Counters", "Points of Interest", "Time Profiler"],
        "CPU Profiler": ["CPU Profiler", "Hangs", "Points of Interest"],
        "Core AI": ["Core AI", "Time Profiler"], "Data Persistence": [], "File Activity": [],
        "Foundation Models": [], "Game Memory": ["Allocations", "VM Tracker"],
        "Game Performance": ["Hangs", "Points of Interest", "Time Profiler"],
        "Game Performance Overview": ["Metal Performance Overview", "Time Profiler"],
        "Leaks": ["Allocations", "Leaks", "Points of Interest"],
        "Logging": ["os_log", "os_signpost"],
        "Metal System Trace": ["Hangs", "Time Profiler"],
        "Network": ["Points of Interest"],
        "Processor Trace": ["Points of Interest", "Processor Trace"],
        "Swift Concurrency": ["Hangs", "Points of Interest", "Time Profiler"],
        "SwiftUI": ["Hangs", "SwiftUI", "Time Profiler"],
        "System Trace": ["Hangs", "Points of Interest", "Time Profiler"],
        "Time Profiler": ["Hangs", "Points of Interest", "Time Profiler"]
    ]
    static let immediateUnsupported: Set<String> = [
        "Animation Hitches", "App Launch", "Audio System Trace", "CPU Counters",
        "File Activity", "Game Performance", "Game Performance Overview",
        "Processor Trace", "SwiftUI", "System Trace"
    ]
}

/// Patches a disposable NSKeyedArchiver template; the installed template is
/// only read. UID references are preserved, and only existing option slots
/// are changed. The recorder loads the disposable copy via XRTrace.
enum TemplateArchivePatch {
    private static func nativeBooleanOptions(_ group: String, _ fields: [String: Bool?]) -> String? {
        let values = fields.compactMapValues { $0 }
        guard !values.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return "\(group)|\(json)"
    }

    private static func nativeAllocationOptions(_ value: AllocationSettings) -> String? {
        var options: [String: Any] = [:]
        if let x = value.discardEventsForFreedMemory { options["discardEventsForFreedMemory"] = x }
        if let x = value.discardUnrecordedDataUponStop { options["discardUnrecordedDataUponStop"] = x }
        if let x = value.enableNSZombieDetection { options["enableNSZombieDetection"] = x }
        if let x = value.identifyVirtualCppObjects { options["identifyVirtualCppObjects"] = x }
        if let x = value.onlyTrackVMAllocations { options["onlyTrackVMAllocations"] = x }
        if let x = value.recordReferenceCounts { options["recordReferenceCounts"] = x }
        if let filters = value.recordedTypes {
            options["recordedTypes"] = filters.map {
                ["action": $0.action.rawValue, "enabled": $0.enabled,
                 "match": $0.match.rawValue, "type": $0.type]
            }
        }
        guard !options.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: options, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return "Allocations|\(json)"
    }

    static func nativeOptionSpecifications(_ settings: [TraceSetting]) -> String {
        settings.compactMap { setting -> String? in
            switch setting {
            case let .hangs(threshold, inversions):
                let milliseconds = [500, 250, 100, 33][threshold.rawValue]
                return "Hangs|{\"hangsThreshold\":\(milliseconds),\"detectPriorityInversions\":\(inversions)}"
            case let .pointsOfInterest(exclude):
                return "Points of Interest|{\"excludeOSLogs\":\(exclude)}"
            case let .coreAnimationCommits(value):
                return "Core Animation Commits|{\"expensiveCommitSampling\":\(value.expensiveCommitSampling)}"
            case let .allocations(value):
                return nativeAllocationOptions(value)
            case let .metalPerformance(value):
                return nativeBooleanOptions("Metal Performance Overview", [
                    "perFrameMetrics": value.perFrameMetrics,
                    "shaderCompilationMetrics": value.shaderCompilationMetrics
                ])
            case let .swiftUI(value):
                return nativeBooleanOptions("SwiftUI", ["enableLayoutTracing": value])
            case let .osLog(value):
                return nativeBooleanOptions("os_log", ["recordAllProcessesInSingleProcessMode": value])
            case let .osSignpost(allProcesses, subsystems):
                let options: [String: Any] = [
                    "dynamicTracingEnabledSubsystems": subsystems,
                    "recordAllProcessesInSingleProcessMode": allProcesses
                ]
                guard let data = try? JSONSerialization.data(withJSONObject: options, options: [.sortedKeys]),
                      let json = String(data: data, encoding: .utf8) else { return nil }
                return "os_signpost|\(json)"
            default:
                return nil
            }
        }.joined(separator: ";")
    }
    static func copy(template: TraceTemplate, settings: [TraceSetting]) throws(RecordingError) -> URL {
        guard let path = template.instrumentName.withCString({ instrumentsTemplatePath($0) }) else {
            throw .invalidPlan("Template is not installed: \(template.instrumentName)")
        }
        defer { free(path) }
        let source = URL(fileURLWithPath: String(cString: path))
        do {
            let data = try Data(contentsOf: source)
            guard var archive = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  var objects = archive["$objects"] as? [Any] else {
                throw RecordingError.invalidPlan("Template archive has an unexpected structure")
            }
            for setting in settings {
                switch setting {
                case let .recordingMode(mode):
                    guard let i = objects.firstIndex(where: { className($0, objects: objects) == "XRRecordingOptions" }),
                          var options = objects[i] as? [String: Any] else {
                        throw RecordingError.invalidPlan("Recording mode is unavailable in this template")
                    }
                    options["recordingMode"] = mode == .immediate ? 1 : 2
                    objects[i] = options
                case let .captureLast(capture):
                    guard let i = objects.firstIndex(where: { className($0, objects: objects) == "XRRecordingOptions" }),
                          var options = objects[i] as? [String: Any] else {
                        throw RecordingError.invalidPlan("Capture Last is unavailable in this template")
                    }
                    switch capture {
                    case .disabled: options["windowLimit"] = 0
                    case let .last(duration): options["windowLimit"] = nanoseconds(duration)
                    }
                    objects[i] = options
                case let .timeProfiler(value):
                    try switchValue("highFrequency", value.highFrequencySampling, objects: &objects)
                    try switchValue("highFreqSampling", value.highFrequencySampling, objects: &objects)
                    try switchValue("recordWaitingThreads", value.recordWaitingThreads, objects: &objects)
                    try switchValue("recordKernelStacks", value.recordKernelCallstacks, objects: &objects)
                    try switchValue("contextSwitchSampling", value.contextSwitchSampling, objects: &objects)
                case let .cpuProfiler(value):
                    try switchValue("highFrequency", value.highFrequencySampling, objects: &objects)
                    try switchValue("recordKernelStack", value.recordKernelCallstacks, objects: &objects)
                case let .hangs(threshold, _):
                    if TemplateSettingsCatalog.groups[template.instrumentName]?.contains("Hangs") == true {
                        try switchValue("hangsThreshold", threshold.rawValue, objects: &objects)
                    }
                case .pointsOfInterest:
                    break
                case let .cpuCounters(value):
                    var changes: [String: Any] = [:]
                    if let x = value.pmiThreshold { changes["pmiThreshold"] = x }
                    if let x = value.processBucketSize { changes["processBucketSize"] = x }
                    if let x = value.sampleByTime { changes["sampleByTime"] = x }
                    if let x = value.useDebuggingInformation { changes["useDebuggingInformation"] = x }
                    if let x = value.useHighFrequencyForGuidedMode { changes["useHighFrequencyForGuidedMode"] = x }
                    if let x = value.useHighFrequencyForManualMode { changes["useHighFrequencyForManualMode"] = x }
                    try encodedOptions(changes, marker: "pmiThreshold", objects: &objects)
                case .allocations, .metalPerformance, .swiftUI, .osLog, .osSignpost:
                    break // Applied to the loaded native instrument control state.
                case .coreAnimationCommits:
                    break
                case let .processorTrace(value):
                    var changes: [String: Any] = [:]
                    if let x = value.bufferSizeFill { changes["bufferSizeFill"] = x }
                    if let x = value.bufferSizeWrap { changes["bufferSizeWrap"] = x }
                    if let x = value.preventDataLoss { changes["throttleEnabled"] = x }
                    try encodedOptions(changes, marker: "bufferSizeFill", objects: &objects)
                case let .leaks(mode):
                    switch mode {
                    case .manual:
                        try templateDataValue("com.apple.instruments.leaks.XRLeakConfigurationAutoLeaksKey", false, objects: &objects)
                    case let .automatic(interval):
                        try templateDataValue("com.apple.instruments.leaks.XRLeakConfigurationAutoLeaksKey", true, objects: &objects)
                        try templateDataValue("com.apple.instruments.leaks.XRLeakConfigurationCheckIntervalKey",
                                              microseconds(interval), objects: &objects)
                    }
                case let .vmTracker(value):
                    if let interval = value.snapshotInterval {
                        try templateDataValue("XRVMInstrumentKey_snapRateMicros", microseconds(interval), objects: &objects)
                    }
                    if let automatic = value.automaticSnapshots {
                        try templateDataValue("XRVMInstrumentKey_autoSnapshot", automatic, objects: &objects)
                    }
                }
            }
            archive["$objects"] = objects
            let output = FileManager.default.temporaryDirectory
                .appendingPathComponent("instruments-plan-\(UUID().uuidString).tracetemplate")
            try PropertyListSerialization.data(fromPropertyList: archive, format: .binary, options: 0)
                .write(to: output, options: .atomic)
            return output
        } catch let error as RecordingError { throw error }
        catch { throw .invalidPlan("Could not prepare template settings: \(error)") }
    }

    private static func uid(_ value: Any) -> Int? {
        let description = String(describing: value)
        guard description.hasPrefix("<CFKeyedArchiverUID ") else { return nil }
        guard let start = description.range(of: "{value = "),
              let end = description[start.upperBound...].firstIndex(of: "}") else { return nil }
        return Int(description[start.upperBound..<end])
    }

    private static func className(_ value: Any, objects: [Any]) -> String? {
        guard let dict = value as? [String: Any], let ref = dict["$class"].flatMap(uid),
              objects.indices.contains(ref), let cls = objects[ref] as? [String: Any] else { return nil }
        return cls["$classname"] as? String
    }

    private static func switchValue(_ key: String, _ newValue: Any?, objects: inout [Any]) throws(RecordingError) {
        guard let newValue else { return }
        // The recorder has a command-wide state and instruments can have
        // their own states (Points of Interest uses the latter).
        let states = objects.enumerated().compactMap { _, object -> (Int, Int?)? in
            guard className(object, objects: objects) == "XRInstrumentControlState",
                  let state = object as? [String: Any] else { return nil }
            guard let stateRef = state["state"].flatMap(uid) else { return nil }
            return (stateRef, state["switchAttributes"].flatMap(uid))
        }
        let location = states.compactMap { index, attributes -> (Int, Int, Int?)? in
            guard let dictionary = objects[index] as? [String: Any],
                  let keys = dictionary["NS.keys"] as? [Any],
                  let position = keys.firstIndex(where: { ref in
                      guard let i = uid(ref), objects.indices.contains(i) else { return false }
                      return objects[i] as? String == key
                  }) else { return nil }
            return (index, position, attributes)
        }.last
        guard let (dictionaryRef, position, attributesRef) = location,
              var dictionary = objects[dictionaryRef] as? [String: Any],
              var values = dictionary["NS.objects"] as? [Any] else {
            throw .invalidPlan("Private switch is absent: \(key)")
        }
        let target = objects.firstIndex(where: { object in
            guard let number = object as? NSNumber, type(of: object) != Data.self else { return false }
            if let boolean = newValue as? Bool { return CFGetTypeID(number) == CFBooleanGetTypeID() && number.boolValue == boolean }
            if let integer = newValue as? Int { return CFGetTypeID(number) != CFBooleanGetTypeID() && number.intValue == integer }
            return false
        })
        let reference = target.flatMap { wanted -> Any? in
            for object in objects {
                guard let dictionary = object as? [String: Any] else { continue }
                for item in dictionary.values {
                    if uid(item) == wanted { return item }
                    if let array = item as? [Any], let match = array.first(where: { uid($0) == wanted }) {
                        return match
                    }
                }
            }
            return nil
        }
        guard let reference else {
            throw .invalidPlan("Private switch value is not represented in this template: \(key)=\(newValue)")
        }
        values[position] = reference
        dictionary["NS.objects"] = values
        objects[dictionaryRef] = dictionary
        if let attributesRef,
           var attributes = objects[attributesRef] as? [String: Any],
           let keys = attributes["NS.keys"] as? [Any],
           var attributeValues = attributes["NS.objects"] as? [Any],
           let position = keys.firstIndex(where: { ref in
               guard let i = uid(ref), objects.indices.contains(i) else { return false }
               return objects[i] as? String == key
           }) {
            attributeValues[position] = reference
            attributes["NS.objects"] = attributeValues
            objects[attributesRef] = attributes
        }
    }

    private static func encodedOptions(_ changes: [String: Any], marker: String,
                                       objects: inout [Any]) throws(RecordingError) {
        guard !changes.isEmpty else { return }
        for i in objects.indices {
            guard let bytes = objects[i] as? Data,
                  var json = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any],
                  json[marker] != nil else { continue }
            for (key, value) in changes { json[key] = value }
            guard JSONSerialization.isValidJSONObject(json) else {
                throw .invalidPlan("Invalid encoded instrument settings")
            }
            do { objects[i] = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]) }
            catch { throw .invalidPlan("Could not encode instrument settings") }
            return
        }
        throw .invalidPlan("Instrument option archive is absent: \(marker)")
    }


    static func microseconds(_ duration: Duration) -> Int {
        Int(duration.components.seconds * 1_000_000
            + duration.components.attoseconds / 1_000_000_000_000)
    }

    static func nanoseconds(_ duration: Duration) -> Int {
        Int(duration.components.seconds * 1_000_000_000
            + duration.components.attoseconds / 1_000_000_000)
    }

    private static func templateDataValue(_ key: String, _ replacement: Any,
                                          objects: inout [Any]) throws(RecordingError) {
        guard let keyIndex = objects.firstIndex(where: { $0 as? String == key }) else {
            throw .invalidPlan("Private template-data key is absent: \(key)")
        }
        for i in objects.indices {
            guard var dictionary = objects[i] as? [String: Any],
                  let keys = dictionary["NS.keys"] as? [Any],
                  var values = dictionary["NS.objects"] as? [Any],
                  let position = keys.firstIndex(where: { uid($0) == keyIndex }),
                  let oldIndex = uid(values[position]) else { continue }
            if let boolean = replacement as? Bool {
                guard let newIndex = objects.firstIndex(where: {
                    guard let number = $0 as? NSNumber else { return false }
                    return CFGetTypeID(number) == CFBooleanGetTypeID() && number.boolValue == boolean
                }), let newReference = findReference(to: newIndex, in: objects) else {
                    throw .invalidPlan("Boolean archive value is unavailable for \(key)")
                }
                values[position] = newReference
                dictionary["NS.objects"] = values
                objects[i] = dictionary
            } else if let number = replacement as? Int {
                // These interval scalar nodes are unique in the installed archive.
                let uses = objects.compactMap { ($0 as? [String: Any])?["NS.objects"] as? [Any] }
                    .flatMap { $0 }.filter { uid($0) == oldIndex }.count
                guard uses == 1 else { throw .invalidPlan("Shared template-data value cannot be safely patched: \(key)") }
                objects[oldIndex] = number
            }
            return
        }
        throw .invalidPlan("Private template-data value is absent: \(key)")
    }

    private static func findReference(to index: Int, in objects: [Any]) -> Any? {
        for object in objects {
            guard let dictionary = object as? [String: Any] else { continue }
            for item in dictionary.values {
                if uid(item) == index { return item }
                if let array = item as? [Any], let match = array.first(where: { uid($0) == index }) {
                    return match
                }
            }
        }
        return nil
    }
}
