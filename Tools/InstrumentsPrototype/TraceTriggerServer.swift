import Darwin
import Foundation

// The app and private recorder deliberately live in different processes. This
// newline-delimited loopback protocol keeps private frameworks out of the Mac
// Catalyst binary: one JSON request, READY after Instruments is running, STOP
// after the measured operation, then DONE <path> or ERROR <message>.
private struct TraceRequest: Decodable {
    let pid: Int32
    let executablePath: String
    let label: String
    let durationSeconds: Double
    let templateName: String?
    let additionalInstruments: [String]?
    let highFrequency: Bool?
    let token: String?
}

private func sendLine(_ line: String, to socketFD: Int32) {
    let bytes = Array(line.utf8)
    bytes.withUnsafeBytes { buffer in
        guard let base = buffer.baseAddress else { return }
        var sentCount = 0
        while sentCount < buffer.count {
            let count = send(socketFD, base.advanced(by: sentCount), buffer.count - sentCount, 0)
            if count <= 0 { return }
            sentCount += count
        }
    }
}

private func readLine(from socketFD: Int32) -> Data? {
    var data = Data()
    var byte: UInt8 = 0
    while data.count < 4096 {
        let count = recv(socketFD, &byte, 1, 0)
        if count <= 0 { return nil }
        if byte == 10 { return data }
        data.append(byte)
    }
    return nil
}

private func handleRequest(on clientFD: Int32) {
    guard let data = readLine(from: clientFD),
          let request = try? JSONDecoder().decode(TraceRequest.self, from: data),
          request.pid > 0 else {
        sendLine("ERROR invalid request\n", to: clientFD)
        return
    }

    // Loopback is the primary boundary. A token is optional for users who want
    // protection from unrelated local processes while the host is running.
    if let requiredToken = ProcessInfo.processInfo.environment["INSTRUMENTS_TRACE_TOKEN"],
       !requiredToken.isEmpty, request.token != requiredToken {
        sendLine("ERROR unauthorized\n", to: clientFD)
        return
    }

    let safeLabel = String(request.label.map { character in
        character.isLetter || character.isNumber ? character : "-"
    }).prefix(64)
    let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["INSTRUMENTS_OUTPUT_DIRECTORY"] ?? "/private/tmp/SortSymphonyTraces", isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stamp = Int(Date().timeIntervalSince1970 * 1000)
        let unique = UUID().uuidString.prefix(8)
        let output = directory.appendingPathComponent("\(safeLabel.isEmpty ? "trace" : String(safeLabel))-\(request.pid)-\(stamp)-\(unique).trace")
        let template: TraceTemplate
        switch request.templateName ?? "CPU Profiler" {
        case "CPU Profiler": template = .cpuProfiler
        case "Time Profiler": template = .timeProfiler
        case "File Activity": template = .fileActivity
        case "Activity Monitor": template = .activityMonitor
        case "Allocations": template = .allocations
        case "Animation Hitches": template = .animationHitches
        case "Audio System Trace": template = .audioSystemTrace
        case "CPU Counters": template = .cpuCounters
        case "Core AI": template = .coreAI
        case "Leaks": template = .leaks
        case "Game Memory": template = .gameMemory
        case "Game Performance": template = .gamePerformance
        case "Game Performance Overview": template = .gamePerformanceOverview
        case "Swift Concurrency": template = .swiftConcurrency
        case "SwiftUI": template = .swiftUI
        case "Logging": template = .logging
        case "Metal System Trace": template = .metalSystemTrace
        case "System Trace": template = .systemTrace
        case "Data Persistence": template = .dataPersistence
        default:
            sendLine("ERROR unsupported template\n", to: clientFD)
            return
        }
        let additionalInstruments = try (request.additionalInstruments ?? []).map { identifier in
            guard let instrument = TraceInstrument(rawValue: identifier) else {
                throw RecordingError.invalidPlan("Unsupported instrument: \(identifier)")
            }
            return instrument
        }
        var settings: [TraceSetting] = []
        if request.highFrequency == true {
            switch template {
            case .cpuProfiler:
                settings.append(.cpuProfiler(.init(highFrequencySampling: true)))
            case .timeProfiler:
                settings.append(.timeProfiler(.init(highFrequencySampling: true)))
            default:
                throw RecordingError.invalidPlan("High Frequency is unavailable for \(template.instrumentName)")
            }
        }
        // Unified logging caches subsystem enablement when an OSSignposter is
        // constructed. Apply this option before READY so the app can lazily
        // construct its signposter afterward and receive actual rows.
        let capturesSignposts: Bool = {
            if case .logging = template { return true }
            return additionalInstruments.contains(.osSignpost)
        }()
        if capturesSignposts {
            settings.append(.osSignpost(
                recordAllProcessesInSingleProcessMode: false,
                dynamicTracingEnabledSubsystems: ["com.nhubbard.SortSymphony"]))
        }
        let plan = try TracePlan.recording(
            template,
            of: .attach(pid: request.pid, executable: URL(fileURLWithPath: request.executablePath)),
            for: .seconds(request.durationSeconds), savingTo: output,
            adding: additionalInstruments, settings: settings)
        // RecordingSession is intentionally blocking here. The server handles
        // one trace at a time because Xcode's private recorder has shared
        // command state and concurrent runs were not validated.
        var stopData = Data()
        let saved = try RecordingSession(plan: plan).record(
            onStarted: { sendLine("READY\n", to: clientFD) },
            stopWhen: {
                var bytes = [UInt8](repeating: 0, count: 64)
                let received = bytes.withUnsafeMutableBytes {
                    recv(clientFD, $0.baseAddress, $0.count, MSG_DONTWAIT)
                }
                if received == 0 { return true }
                guard received > 0 else { return false }
                stopData.append(contentsOf: bytes.prefix(received))
                guard stopData.count <= 128 else { return true }
                return stopData == Data("STOP\n".utf8)
            }
        )
        sendLine("DONE \(saved.path)\n", to: clientFD)
        FileHandle.standardError.write(Data("Trace completed: \(saved.path)\n".utf8))
    } catch {
        sendLine("ERROR \(error)\n", to: clientFD)
        FileHandle.standardError.write(Data("Trace request failed: \(error)\n".utf8))
    }
}

/// Runs the single-recording loopback host inside the signed xctrace carrier.
/// This function returns only if socket setup fails.
func runTraceTriggerServer(port: UInt16) -> Int32 {
    let serverFD = socket(AF_INET, SOCK_STREAM, 0)
    guard serverFD >= 0 else { return 11 }
    defer { close(serverFD) }

    var enabled: Int32 = 1
    _ = setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, &enabled, socklen_t(MemoryLayout<Int32>.size))
    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = port.bigEndian
    address.sin_addr = in_addr(s_addr: in_addr_t(0x7f000001).bigEndian)
    let bindResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(serverFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    guard bindResult == 0, listen(serverFD, 4) == 0 else { return 12 }
    FileHandle.standardError.write(Data("Trace trigger listening on 127.0.0.1:\(port)\n".utf8))

    while true {
        let clientFD = accept(serverFD, nil, nil)
        if clientFD < 0 { continue }
        _ = setsockopt(clientFD, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))
        var receiveTimeout = timeval(tv_sec: 10, tv_usec: 0)
        _ = setsockopt(clientFD, SOL_SOCKET, SO_RCVTIMEO, &receiveTimeout,
                       socklen_t(MemoryLayout<timeval>.size))
        handleRequest(on: clientFD)
        close(clientFD)
    }
}
