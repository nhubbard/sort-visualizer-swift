import Foundation
import SortAudioCore
import Testing

@testable import SortAudioBridgeKit

/// A real Unix domain socket in a temp directory stands in for the App Group container — this
/// module's own tests don't need the real entitlement to prove the server/client wire protocol and
/// connection lifecycle work; `SortAudioBridgePath` (the actual App-Group-derived path) is
/// exercised only by the real app/extension at run time.
private final class RecordingSink: SortAudioEventSink, @unchecked Sendable {
  private let lock = NSLock()
  private var _received: [(event: SortToneEvent, noteRange: ClosedRange<Int>)] = []
  var received: [(event: SortToneEvent, noteRange: ClosedRange<Int>)] {
    lock.withLock { _received }
  }
  let onReceive: @Sendable () -> Void

  init(onReceive: @escaping @Sendable () -> Void) {
    self.onReceive = onReceive
  }

  func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>) {
    lock.withLock { _received.append((event, noteRange)) }
    onReceive()
  }
}

/// Same "class + NSLock" safe-capture idiom as `RecordingSink` above — a plain `var` captured by
/// `onRemoteControlCommandReceived` (a `@Sendable` closure) fails Swift 6 strict concurrency, even
/// though the lock genuinely makes it safe.
private final class LastCommandBox: @unchecked Sendable {
  private let lock = NSLock()
  private var value: RemoteControlCommand?
  func set(_ newValue: RemoteControlCommand) { lock.withLock { value = newValue } }
  func get() -> RemoteControlCommand? { lock.withLock { value } }
}

@Suite
struct SortAudioBridgeIntegrationTests {
  /// Deliberately under `/tmp` rather than `FileManager.default.temporaryDirectory` — macOS
  /// resolves the latter to a long per-process `/var/folders/...` path, which combined with even a
  /// short filename can exceed `sockaddr_un.sun_path`'s 104-byte limit and fail `bind()` for a
  /// reason that has nothing to do with the bridge logic under test. `/tmp` is a short, fixed path.
  private func makeTempSocketPath() -> String {
    "/tmp/sabk-\(UUID().uuidString.prefix(8)).sock"
  }

  @Test
  func clientReceivesWhatTheServerBroadcasts() async throws {
    let socketPath = makeTempSocketPath()
    defer { try? FileManager.default.removeItem(atPath: socketPath) }

    let server = SortAudioBridgeServer()
    try server.start(socketPath: socketPath)

    let event = SortToneEvent(
      value: 12, range: 0...255, holdSeconds: 0.2, index: 3, arraySize: 255, operationKind: .swap)
    let noteRange = 36...96

    try await confirmation { received in
      let sink = RecordingSink(onReceive: { received() })
      let client = SortAudioBridgeClient(socketPath: socketPath, sink: sink)
      client.start()

      // Poll for the connection to register before broadcasting — the client connects
      // asynchronously, and a broadcast sent before any connection exists has nothing to reach.
      let deadline = ContinuousClock.now.advanced(by: .seconds(5))
      while !server.hasConnectedClients, ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
      }
      #expect(server.hasConnectedClients)

      server.broadcast(event, noteRange: noteRange)
      try await Task.sleep(for: .milliseconds(500))

      #expect(sink.received.count == 1)
      #expect(sink.received.first?.event == event)
      #expect(sink.received.first?.noteRange == noteRange)

      client.stop()
    }

    server.stop()
  }

  @Test
  func hasConnectedClientsReflectsNoConnections() {
    let server = SortAudioBridgeServer()
    #expect(!server.hasConnectedClients)
  }

  /// The reverse direction the AU-hosted remote (`AUDIO_UNIT_PLAN.md` §7) depends on — same
  /// connection, opposite flow, previously untested since the server was write-only before the
  /// remote existed.
  @Test
  func serverReceivesRemoteControlCommandsFromClient() async throws {
    let socketPath = makeTempSocketPath()
    defer { try? FileManager.default.removeItem(atPath: socketPath) }

    let server = SortAudioBridgeServer()
    try server.start(socketPath: socketPath)
    defer { server.stop() }

    let sink = RecordingSink(onReceive: {})
    let client = SortAudioBridgeClient(socketPath: socketPath, sink: sink)
    client.start()
    defer { client.stop() }

    let deadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !server.hasConnectedClients, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(server.hasConnectedClients)

    let lastCommandBox = LastCommandBox()
    try await confirmation { received in
      server.onRemoteControlCommandReceived = { command in
        lastCommandBox.set(command)
        received()
      }

      client.sendRemoteControlCommand(.regenerate)
      try await Task.sleep(for: .milliseconds(500))

      #expect(lastCommandBox.get() == .regenerate)
    }
  }
}
