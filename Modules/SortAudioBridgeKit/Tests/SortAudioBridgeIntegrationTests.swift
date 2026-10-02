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

private final class AppGroupFileManager: FileManager {
  var appGroupContainer: URL?

  override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
    guard groupIdentifier == SortAudioBridgePath.appGroupIdentifier else { return nil }
    return appGroupContainer
  }
}

private final class ConnectedCountBox: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0
  func recordConnection() { lock.withLock { count += 1 } }
  var connectionCount: Int { lock.withLock { count } }
}

@Suite
struct SortAudioBridgeIntegrationTests {
  @Test
  func appGroupSocketPathRejectsMissingOrOverlongContainers() {
    let manager = AppGroupFileManager()
    #expect(SortAudioBridgePath.socketPath(fileManager: manager) == nil)

    manager.appGroupContainer = URL(fileURLWithPath: "/tmp/group")
    #expect(SortAudioBridgePath.socketPath(fileManager: manager) == "/tmp/group/b.sock")

    manager.appGroupContainer = URL(fileURLWithPath: "/tmp/" + String(repeating: "x", count: 100))
    #expect(SortAudioBridgePath.socketPath(fileManager: manager) == nil)
  }

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

  /// The reverse direction the AU-hosted remote (Documentation/docs/architecture/audio.md) depends on — same
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

  @Test
  func clientReconnectsAfterServerRestartsAtTheSameSocketPath() async throws {
    let socketPath = makeTempSocketPath()
    defer { try? FileManager.default.removeItem(atPath: socketPath) }

    let firstServer = SortAudioBridgeServer()
    try firstServer.start(socketPath: socketPath)
    let sink = RecordingSink(onReceive: {})
    let client = SortAudioBridgeClient(socketPath: socketPath, sink: sink)
    client.start()
    defer { client.stop() }

    let initialDeadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !firstServer.hasConnectedClients, ContinuousClock.now < initialDeadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(firstServer.hasConnectedClients)
    firstServer.stop()

    // The old listener leaves a socket-file entry. Starting at the same path must remove it,
    // and the existing client must retry without its AU host constructing another client.
    let restartedServer = SortAudioBridgeServer()
    try restartedServer.start(socketPath: socketPath)
    defer { restartedServer.stop() }

    let reconnectDeadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !restartedServer.hasConnectedClients, ContinuousClock.now < reconnectDeadline {
      try await Task.sleep(for: .milliseconds(20))
    }
    #expect(restartedServer.hasConnectedClients)

    let event = SortToneEvent(
      value: 42, range: 0...255, holdSeconds: 0.1, index: 4, arraySize: 64,
      operationKind: .compare)
    restartedServer.broadcast(event, noteRange: 48...84)
    let deliveryDeadline = ContinuousClock.now.advanced(by: .seconds(3))
    while sink.received.isEmpty, ContinuousClock.now < deliveryDeadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(sink.received.first?.event == event)
    #expect(sink.received.first?.noteRange == 48...84)
  }

  @Test
  func oneBroadcastReachesTwoConnectedAudioUnitClients() async throws {
    let socketPath = makeTempSocketPath()
    defer { try? FileManager.default.removeItem(atPath: socketPath) }
    let server = SortAudioBridgeServer()
    let connectionEvents = ConnectedCountBox()
    server.onConnectedClientsChanged = { connected in
      if connected { connectionEvents.recordConnection() }
    }
    try server.start(socketPath: socketPath)
    defer { server.stop() }

    let firstSink = RecordingSink(onReceive: {})
    let secondSink = RecordingSink(onReceive: {})
    let firstClient = SortAudioBridgeClient(socketPath: socketPath, sink: firstSink)
    let secondClient = SortAudioBridgeClient(socketPath: socketPath, sink: secondSink)
    firstClient.start()
    secondClient.start()
    defer {
      firstClient.stop()
      secondClient.stop()
    }

    let connectionDeadline = ContinuousClock.now.advanced(by: .seconds(5))
    while connectionEvents.connectionCount < 2, ContinuousClock.now < connectionDeadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(connectionEvents.connectionCount == 2)

    let event = SortToneEvent(
      value: 81, range: 0...255, holdSeconds: 0.2, index: 9, arraySize: 128,
      operationKind: .swap)
    server.broadcast(event, noteRange: 36...96)
    let deliveryDeadline = ContinuousClock.now.advanced(by: .seconds(3))
    while (firstSink.received.isEmpty || secondSink.received.isEmpty),
      ContinuousClock.now < deliveryDeadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(firstSink.received.first?.event == event)
    #expect(secondSink.received.first?.event == event)
    #expect(firstSink.received.first?.noteRange == 36...96)
    #expect(secondSink.received.first?.noteRange == 36...96)
  }
}
