import Foundation
import SettingsKit
import SortAudioCore
import Synchronization
import ToneKitDSP
import Testing
#if targetEnvironment(macCatalyst)
import SortAudioBridgeKit
#endif

@testable import AudioEngineKit

@MainActor
private final class TestAudioEngine: AudioEngineControlling {
  enum StartError: Error { case unavailable }
  var startCount = 0
  var stopCount = 0
  var failsToStart = false

  func start() throws {
    startCount += 1
    if failsToStart { throw StartError.unavailable }
  }

  func stop() { stopCount += 1 }
}

/// Each test calls the service on the main actor, matching AudioService's production isolation.
private final class RecordingToneSink: SortAudioEventSink, @unchecked Sendable {
  var sent: [(SortToneEvent, ClosedRange<Int>)] = []
  func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>) {
    sent.append((event, noteRange))
  }
}

#if targetEnvironment(macCatalyst)
private final class TestAudioBridge: AudioBridgeServing, @unchecked Sendable {
  var hasConnectedClients = false
  var onConnectedClientsChanged: (@Sendable (Bool) -> Void)?
  var onListenerStateChanged: (@Sendable (SortAudioBridgeServer.ListenerState) -> Void)?
  var onRemoteControlCommandReceived: (@Sendable (RemoteControlCommand) -> Void)?
  var startedPaths: [String] = []
  var stopCount = 0
  var broadcasts: [(SortToneEvent, ClosedRange<Int>)] = []
  var failsToStart = false

  func start(socketPath: String) throws {
    startedPaths.append(socketPath)
    if failsToStart { throw TestAudioEngine.StartError.unavailable }
  }

  func stop() { stopCount += 1 }

  func broadcast(_ event: SortToneEvent, noteRange: ClosedRange<Int>) {
    broadcasts.append((event, noteRange))
  }
}
#endif

@MainActor
@Suite
struct NoOpAudioServiceTests {
  @Test
  func bridgeStatusUsesDistinctUserFacingMessages() {
    #expect(BridgeConnectionStatus.disabledByUser.displayText == "Disabled")
    #expect(BridgeConnectionStatus.notStarted.displayText == "Not Started Yet")
    #expect(BridgeConnectionStatus.unsupportedPlatform.displayText == "Not Available on This Platform")
    #expect(BridgeConnectionStatus.unavailable.displayText == "Unavailable")
    #expect(BridgeConnectionStatus.listening.displayText == "Waiting for Connection")
    #expect(BridgeConnectionStatus.connected.displayText == "Connected")
  }

  @Test
  func conformsAndNeverThrowsOrCrashes() throws {
    let service: any AudioPlaying = NoOpAudioService()
    try service.start()
    service.play(
      value: 5, in: 0...10, holdSeconds: 0.05, index: 0, arraySize: 10, operationKind: .compare)
    service.stop()
  }

  @Test
  func audioBridgeRemainsInactiveUntilEnabledAndCanBeTurnedOffWithoutStartingAudio() {
    let suiteName = "AudioServiceStateTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = false
    let disabledService = AudioService(settings: settings)

    #if targetEnvironment(macCatalyst)
      #expect(disabledService.bridgeStatus == .disabledByUser)
      settings.audioUnitBridgeEnabled = true
      let optedInService = AudioService(settings: settings)
      #expect(optedInService.bridgeStatus == .notStarted)
      optedInService.setAudioUnitBridgeEnabled(false)
      #expect(optedInService.bridgeStatus == .disabledByUser)
    #else
      #expect(disabledService.bridgeStatus == .unsupportedPlatform)
    #endif
  }

  @Test
  func audioServiceStartsOnceRoutesLocalEventsWithLiveNoteRangeAndStopsOnce() {
    let suiteName = "AudioServiceRoutingTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = false
    let engine = TestAudioEngine()
    let sink = RecordingToneSink()
    let renderer = AudioServiceDependencies.makeRenderer()
    #if targetEnvironment(macCatalyst)
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: engine, renderer: renderer, sink: sink, bridgeServer: TestAudioBridge(),
      socketPath: { nil }))
    #else
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: engine, renderer: renderer, sink: sink))
    #endif

    settings.synthNoteRange = 36...72
    service.play(
      value: 7, in: 0...10, holdSeconds: 0.15, index: 2, arraySize: 10,
      operationKind: .compare)
    settings.synthNoteRange = 48...60
    service.play(
      value: 9, in: 0...10, holdSeconds: 0.25, index: 3, arraySize: 10,
      operationKind: .swap)

    #expect(engine.startCount == 1)
    #expect(sink.sent.count == 2)
    #expect(sink.sent.map(\.1) == [36...72, 48...60])
    #expect(sink.sent[0].0 == SortToneEvent(
      value: 7, range: 0...10, holdSeconds: 0.15, index: 2, arraySize: 10,
      operationKind: .compare))
    #expect(sink.sent[1].0.operationKind == .swap)

    service.stop()
    service.stop()
    #expect(engine.stopCount == 1)
    try? service.start()
    #expect(engine.startCount == 2)
  }

  @Test
  func failedAudioStartDropsTheEventAndRetriesOnTheNextOne() {
    let suiteName = "AudioServiceStartFailureTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = false
    let engine = TestAudioEngine()
    engine.failsToStart = true
    let sink = RecordingToneSink()
    let renderer = AudioServiceDependencies.makeRenderer()
    #if targetEnvironment(macCatalyst)
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: engine, renderer: renderer, sink: sink, bridgeServer: TestAudioBridge(),
      socketPath: { nil }))
    #else
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: engine, renderer: renderer, sink: sink))
    #endif

    service.play(
      value: 2, in: 0...10, holdSeconds: 0.1, index: 0, arraySize: 10,
      operationKind: .compare)
    #expect(engine.startCount == 1)
    #expect(sink.sent.isEmpty)
    service.stop()
    #expect(engine.stopCount == 0)

    engine.failsToStart = false
    service.play(
      value: 3, in: 0...10, holdSeconds: 0.1, index: 1, arraySize: 10,
      operationKind: .setValue)
    #expect(engine.startCount == 2)
    #expect(sink.sent.count == 1)
  }

  #if targetEnvironment(macCatalyst)
  @Test
  func bridgeConnectionReplacesLocalPlaybackAndTracksConnectionState() async {
    let suiteName = "AudioServiceBridgeTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = true
    let engine = TestAudioEngine()
    let sink = RecordingToneSink()
    let bridge = TestAudioBridge()
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: engine, renderer: AudioServiceDependencies.makeRenderer(), sink: sink,
      bridgeServer: bridge, socketPath: { "/tmp/audio-service-test.sock" }))

    #expect(service.bridgeStatus == .notStarted)
    service.setAudioUnitBridgeEnabled(true)
    #expect(bridge.startedPaths == ["/tmp/audio-service-test.sock"])
    bridge.onListenerStateChanged?(.listening)
    for _ in 0..<100 where service.bridgeStatus != .listening { await Task.yield() }
    #expect(service.bridgeStatus == .listening)

    bridge.hasConnectedClients = true
    bridge.onConnectedClientsChanged?(true)
    for _ in 0..<100 where service.bridgeStatus != .connected { await Task.yield() }
    #expect(service.bridgeStatus == .connected)
    service.play(
      value: 5, in: 0...10, holdSeconds: 0.2, index: 2, arraySize: 10,
      operationKind: .auxWrite)
    #expect(bridge.broadcasts.count == 1)
    #expect(bridge.broadcasts[0].0.operationKind == .auxWrite)
    #expect(sink.sent.isEmpty)

    bridge.hasConnectedClients = false
    bridge.onConnectedClientsChanged?(false)
    for _ in 0..<100 where service.bridgeStatus != .listening { await Task.yield() }
    service.play(
      value: 6, in: 0...10, holdSeconds: 0.2, index: 3, arraySize: 10,
      operationKind: .compare)
    #expect(sink.sent.count == 1)
    #expect(bridge.broadcasts.count == 1)
    service.setAudioUnitBridgeEnabled(false)
    #expect(bridge.stopCount == 1)
    #expect(service.bridgeStatus == .disabledByUser)
  }

  @Test
  func bridgeDisconnectRestoresRenderedLocalAudio() async {
    let suiteName = "AudioServiceFallbackTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = true
    let renderer = AudioServiceDependencies.makeRenderer()
    renderer.prepare(maxFrameCount: 4096)
    let bridge = TestAudioBridge()
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: TestAudioEngine(), renderer: renderer, sink: LocalToneEventSink(renderer: renderer),
      bridgeServer: bridge, socketPath: { "/tmp/audio-service-fallback-test.sock" }))

    bridge.hasConnectedClients = true
    service.play(
      value: 5, in: 0...10, holdSeconds: 1, index: 2, arraySize: 10,
      operationKind: .compare)
    #expect(bridge.broadcasts.count == 1)
    #expect(renderedPeak(renderer) == 0, "connected playback must not leak into the local voice")

    bridge.hasConnectedClients = false
    bridge.onConnectedClientsChanged?(false)
    for _ in 0..<100 where service.bridgeStatus != .listening { await Task.yield() }
    #expect(service.bridgeStatus == .listening)
    service.play(
      value: 6, in: 0...10, holdSeconds: 1, index: 3, arraySize: 10,
      operationKind: .swap)
    #expect(bridge.broadcasts.count == 1)
    #expect(renderedPeak(renderer) > 0.01, "a disconnected bridge must render a local tone")
  }

  private func renderedPeak(_ renderer: ToneRenderer) -> Float {
    var left = [Float](repeating: 0, count: 4096)
    var right = [Float](repeating: 0, count: 4096)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in
        renderer.render(left: l, right: r, sampleRate: 48000)
      }
    }
    return max(left.map(abs).max() ?? 0, right.map(abs).max() ?? 0)
  }

  @Test
  func bridgeStartupFailureReportsUnavailableWithoutStartingHardware() {
    let suiteName = "AudioServiceBridgeFailureTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = true
    let engine = TestAudioEngine()
    let sink = RecordingToneSink()
    let bridge = TestAudioBridge()
    bridge.failsToStart = true
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: engine, renderer: AudioServiceDependencies.makeRenderer(), sink: sink,
      bridgeServer: bridge, socketPath: { "/tmp/audio-service-failure.sock" }))

    service.setAudioUnitBridgeEnabled(true)
    #expect(service.bridgeStatus == .unavailable)
    #expect(bridge.startedPaths == ["/tmp/audio-service-failure.sock"])
    #expect(engine.startCount == 0)
  }

  @Test
  func missingBridgeContainerAndListenerFailureReportUnavailable() async {
    let suiteName = "AudioServiceBridgeStateTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = true
    let bridge = TestAudioBridge()
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: TestAudioEngine(), renderer: AudioServiceDependencies.makeRenderer(),
      sink: RecordingToneSink(), bridgeServer: bridge, socketPath: { nil }))

    service.setAudioUnitBridgeEnabled(true)
    #expect(service.bridgeStatus == .unavailable)
    #expect(bridge.startedPaths.isEmpty)

    let boundBridge = TestAudioBridge()
    let boundService = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: TestAudioEngine(), renderer: AudioServiceDependencies.makeRenderer(),
      sink: RecordingToneSink(), bridgeServer: boundBridge,
      socketPath: { "/tmp/audio-service-listener.sock" }))
    boundService.setAudioUnitBridgeEnabled(true)
    #expect(boundService.bridgeStatus == .notStarted)
    boundBridge.onListenerStateChanged?(.failed)
    for _ in 0..<100 where boundService.bridgeStatus != .unavailable { await Task.yield() }
    #expect(boundService.bridgeStatus == .unavailable)
  }

  @Test
  func bridgeRemoteCommandReachesTheAppHandler() async {
    let suiteName = "AudioServiceRemoteTests.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer { store.removePersistentDomain(forName: suiteName) }
    let settings = AppSettings(store: store)
    settings.audioUnitBridgeEnabled = true
    let bridge = TestAudioBridge()
    let service = AudioService(settings: settings, dependencies: AudioServiceDependencies(
      engine: TestAudioEngine(), renderer: AudioServiceDependencies.makeRenderer(),
      sink: RecordingToneSink(), bridgeServer: bridge,
      socketPath: { "/tmp/audio-service-remote.sock" }))
    let received = Mutex<RemoteControlCommand?>(nil)
    service.remoteControlHandler = { command in received.withLock { $0 = command } }
    service.setAudioUnitBridgeEnabled(true)

    bridge.onRemoteControlCommandReceived?(.restart)
    for _ in 0..<100 where received.withLock({ $0 }) == nil { await Task.yield() }
    #expect(received.withLock { $0 } == .restart)
  }
  #endif
}
