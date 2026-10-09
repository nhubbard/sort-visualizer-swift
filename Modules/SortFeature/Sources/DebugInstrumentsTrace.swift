#if DEBUG && targetEnvironment(macCatalyst) && LOCAL_INSTRUMENTS_TRACING
import Darwin
import Foundation
import Observation
import os

struct DebugTraceRecord: Codable, Identifiable {
  let id: URL
  let algorithmName: String
  let profileName: String
  let repetitions: Int
  let highFrequency: Bool?
  let processID: Int32?
  let recordedAt: Date

  var url: URL { id }
}

@Observable
@MainActor
final class DebugTraceHistory {
  static let shared = DebugTraceHistory()
  private static let storageKey = "SortSymphony.DebugInstrumentsTraceHistory.v1"

  private(set) var records: [DebugTraceRecord]

  private init() {
    let data = UserDefaults.standard.data(forKey: Self.storageKey)
    records = data.flatMap { try? JSONDecoder().decode([DebugTraceRecord].self, from: $0) } ?? []
  }

  func add(_ record: DebugTraceRecord) {
    records.insert(record, at: 0)
    if records.count > 200 { records.removeLast(records.count - 200) }
    if let data = try? JSONEncoder().encode(records) {
      UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
  }
}

/// Profiles offered by Sort Symphony's opt-in local trace controls.
///
/// Standard cases map to validated macOS templates. The two `CPU +` cases
/// compose an extra instrument with CPU Profiler in the external host.
public enum DebugTraceTemplate: String, CaseIterable, Identifiable, Sendable {
  case cpuProfiler = "CPU Profiler"
  case timeProfiler = "Time Profiler"
  case fileActivity = "File Activity"
  case activityMonitor = "Activity Monitor"
  case allocations = "Allocations"
  case animationHitches = "Animation Hitches"
  case audioSystemTrace = "Audio System Trace"
  case cpuCounters = "CPU Counters"
  case coreAI = "Core AI"
  case leaks = "Leaks"
  case gameMemory = "Game Memory"
  case gamePerformance = "Game Performance"
  case gamePerformanceOverview = "Game Performance Overview"
  case swiftConcurrency = "Swift Concurrency"
  case swiftUI = "SwiftUI"
  case logging = "Logging"
  case metalSystemTrace = "Metal System Trace"
  case systemTrace = "System Trace"
  case dataPersistence = "Data Persistence"
  case cpuAndFileActivity = "CPU + File Activity"
  case cpuAndSignposts = "CPU + Signposts"

  /// The stable picker identity and user-visible profile name.
  public var id: String { rawValue }
  var baseTemplateName: String {
    switch self {
    case .cpuAndFileActivity, .cpuAndSignposts: "CPU Profiler"
    default: rawValue
    }
  }
  var additionalInstruments: [String] {
    switch self {
    case .cpuAndFileActivity: ["com.apple.dt.instruments.fs-syscalls"]
    case .cpuAndSignposts: ["com.apple.dt.os-log-signpost-instrument"]
    default: []
    }
  }
  var supportsHighFrequency: Bool {
    self == .cpuProfiler || self == .timeProfiler || self == .cpuAndFileActivity
      || self == .cpuAndSignposts
  }
}

/// Opt-in bridge to the local Instruments prototype host. Set
/// SORT_SYMPHONY_TRACE=1 in the Mac Catalyst debug scheme to enable it.
public enum DebugInstrumentsTrace {
  private static let signposter = OSSignposter(
    logger: Logger(subsystem: "com.nhubbard.SortSymphony", category: "PointsOfInterest"))
  private struct Request: Encodable {
    let pid: Int32
    let executablePath: String
    let label: String
    let durationSeconds: Double
    let templateName: String
    let additionalInstruments: [String]
    let highFrequency: Bool
    let token: String?
  }

  enum TriggerError: Error {
    case invalidConfiguration
    case cannotConnect(Int32)
    case cannotSend
    case noReadyAcknowledgement(String)
    case noCompletionAcknowledgement(String)
  }

  /// Record one named debug operation in the current app process. The host
  /// acknowledges that recording has started before `operation` runs, then
  /// stops the trace as soon as the operation returns or throws.
  ///
  /// - Parameters:
  ///   - label: A human-readable event label stored in the signpost interval.
  ///   - template: The profile or combined recipe to record.
  ///   - highFrequency: Requests high-frequency sampling when the selected
  ///     profile supports it; ignored for other profiles.
  ///   - durationSeconds: A positive fallback cap used if the app never sends
  ///     its stop message.
  ///   - operation: Synchronous work to execute after the recorder replies
  ///     `READY`.
  /// - Returns: The operation's value and the saved trace URL. When local
  ///   tracing is disabled at runtime, the operation still runs and the URL is
  ///   `nil`.
  /// - Throws: A connection or protocol error, or an error from `operation`.
  ///
  /// The operation runs on the caller's thread. Call this API from a detached
  /// task for CPU-heavy work that must not occupy the main actor.
  public static func run<T>(
    label: String, template: DebugTraceTemplate = .cpuProfiler, highFrequency: Bool = false,
    durationSeconds: Double = 10, operation: () throws -> T
  ) throws -> (value: T, traceURL: URL?) {
    guard ProcessInfo.processInfo.environment["SORT_SYMPHONY_TRACE"] == "1" else {
      return (try operation(), nil)
    }
    let environment = ProcessInfo.processInfo.environment
    guard
      let executablePath = Bundle.main.executablePath,
      let port = UInt16(environment["SORT_SYMPHONY_TRACE_PORT"] ?? "27727"),
      durationSeconds.isFinite, durationSeconds > 0
    else { throw TriggerError.invalidConfiguration }

    let connection = socket(AF_INET, SOCK_STREAM, 0)
    guard connection >= 0 else { throw TriggerError.cannotConnect(errno) }
    defer { close(connection) }
    var enabled: Int32 = 1
    _ = setsockopt(
      connection, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))
    var timeout = timeval(tv_sec: 10, tv_usec: 0)
    _ = setsockopt(
      connection, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = port.bigEndian
    address.sin_addr = in_addr(s_addr: in_addr_t(0x7f000001).bigEndian)
    let connected = withUnsafePointer(to: &address) { pointer in
      pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(connection, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
      }
    }
    guard connected == 0 else { throw TriggerError.cannotConnect(errno) }

    let request = Request(
      pid: getpid(), executablePath: executablePath, label: label,
      durationSeconds: durationSeconds, templateName: template.baseTemplateName,
      additionalInstruments: template.additionalInstruments,
      highFrequency: highFrequency && template.supportsHighFrequency,
      token: environment["SORT_SYMPHONY_TRACE_TOKEN"])
    var payload = try JSONEncoder().encode(request)
    payload.append(10)
    func sendAll(_ bytes: [UInt8]) -> Bool {
      bytes.withUnsafeBytes { buffer in
        guard let base = buffer.baseAddress else { return false }
        var offset = 0
        while offset < buffer.count {
          let sent = send(connection, base.advanced(by: offset), buffer.count - offset, 0)
          guard sent > 0 else { return false }
          offset += sent
        }
        return true
      }
    }
    guard sendAll(Array(payload)) else { throw TriggerError.cannotSend }

    func readLine() -> String {
      var acknowledgement = [UInt8]()
      var byte: UInt8 = 0
      while acknowledgement.count < 4096 {
        let received = recv(connection, &byte, 1, 0)
        guard received == 1 else { break }
        if byte == 10 { break }
        acknowledgement.append(byte)
      }
      return String(decoding: acknowledgement, as: UTF8.self)
    }
    let response = readLine()
    guard response == "READY" else {
      throw TriggerError.noReadyAcknowledgement(response)
    }
    let stopBytes = Array("STOP\n".utf8)
    let interval = signposter.beginInterval(
      "Tape generation", id: signposter.makeSignpostID(), "\(label, privacy: .public)")
    let value: T
    do {
      value = try operation()
    } catch {
      signposter.endInterval("Tape generation", interval)
      _ = sendAll(stopBytes)
      throw error
    }
    signposter.endInterval("Tape generation", interval)
    guard sendAll(stopBytes) else { throw TriggerError.cannotSend }
    // The duration is a fallback cap: the host may already have finished and
    // sent DONE by the time a long operation reaches this point.
    let completion = readLine()
    guard completion.hasPrefix("DONE ") else {
      throw TriggerError.noCompletionAcknowledgement(completion)
    }
    return (value, URL(fileURLWithPath: String(completion.dropFirst(5))))
  }
}
#endif
