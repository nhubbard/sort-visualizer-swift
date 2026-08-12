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

    let event = SortToneEvent(value: 12, range: 0...255, holdSeconds: 0.2)
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
}
