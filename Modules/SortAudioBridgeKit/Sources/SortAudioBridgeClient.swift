import Foundation
import Network
import SortAudioCore
import os

/// The AU extension's side of the companion-mode bridge: connects to the app's Unix domain socket
/// (inside the shared App Group container) and forwards every received `SortToneEvent` to a
/// `SortAudioEventSink` — in practice a `SortAudioCore.LocalToneEventSink` wrapping the extension's
/// own `ToneRenderer`, reused completely unchanged from the standalone app's local-playback path.
///
/// Retries on a short interval while disconnected, since Logic may instantiate the AU before or
/// after the standalone app is running, in either order, and the app may quit/relaunch at any time
/// while the AU stays loaded on a track.
///
/// Every connection attempt's outcome is logged (`log show --predicate 'process ==
/// "AUv3Extension"'`) — since retries happen silently and often (every `reconnectInterval`), this
/// is the only way to tell "still waiting for the app to be running" apart from "the app is running
/// but something about the connection itself is failing" from outside the process.
public final class SortAudioBridgeClient: @unchecked Sendable {
  private let queue = DispatchQueue(label: "com.nhubbard.Sort2.SortAudioBridgeClient")
  private let logger = Logger(subsystem: "com.nhubbard.Sort2.SortAudioBridgeKit", category: "SortAudioBridgeClient")
  private let socketPath: String
  private let sink: any SortAudioEventSink
  private var connection: NWConnection?
  private var isStopped = false
  private static let reconnectInterval: TimeInterval = 1.0

  public init(socketPath: String, sink: any SortAudioEventSink) {
    self.socketPath = socketPath
    self.sink = sink
  }

  public func start() {
    logger.info("starting, will connect to \(self.socketPath, privacy: .public)")
    queue.async { [weak self] in
      self?.connect()
    }
  }

  public func stop() {
    queue.async { [weak self] in
      guard let self else { return }
      isStopped = true
      connection?.cancel()
      connection = nil
    }
  }

  /// The AU-hosted remote (Documentation/docs/architecture/audio.md) calls this from its own UI actions — fire and
  /// forget, a no-op if not currently connected (`connection` is `nil` on `queue` whenever
  /// disconnected), matching this whole architecture's "no connection = silently does nothing" rule.
  public func sendRemoteControlCommand(_ command: RemoteControlCommand) {
    let data = Data(BridgeEnvelope.encodeRemoteControlCommand(command))
    queue.async { [weak self] in
      self?.connection?.send(content: data, completion: .idempotent)
    }
  }

  /// Runs on `queue` — called only from `start()`'s dispatch or `scheduleReconnect`'s
  /// `asyncAfter`, both already on `queue`.
  private func connect() {
    guard !isStopped else { return }
    let params = NWParameters()
    params.defaultProtocolStack.transportProtocol = NWProtocolTCP.Options()
    let endpoint = NWEndpoint.unix(path: socketPath)
    let connection = NWConnection(to: endpoint, using: params)
    self.connection = connection

    connection.stateUpdateHandler = { [weak self] state in
      guard let self else { return }
      switch state {
      case .ready:
        logger.info("connected to bridge server")
        receiveNext(on: connection)
      case .failed(let error):
        logger.notice("connection attempt failed: \(String(describing: error), privacy: .public) — retrying in \(Self.reconnectInterval, privacy: .public)s")
        scheduleReconnect()
      case .cancelled:
        scheduleReconnect()
      default:
        break
      }
    }
    connection.start(queue: queue)
  }

  private func scheduleReconnect() {
    guard !isStopped else { return }
    queue.asyncAfter(deadline: .now() + Self.reconnectInterval) { [weak self] in
      self?.connect()
    }
  }

  /// `minimumIncompleteLength == maximumLength == totalByteCount` reliably yields exactly one
  /// fixed-size envelope per call regardless of how the underlying stream happened to chunk the
  /// bytes — `receive` never delivers more than `maximumLength`, and won't complete with fewer
  /// until either that many are available or the connection ends. The client only expects
  /// `toneEvent` envelopes on this direction; a stray `remoteControlCommand` would just be ignored.
  private func receiveNext(on connection: NWConnection) {
    connection.receive(
      minimumIncompleteLength: BridgeEnvelope.totalByteCount,
      maximumLength: BridgeEnvelope.totalByteCount
    ) { [weak self] content, _, isComplete, error in
      guard let self else { return }
      if let content, case .toneEvent(let event, let noteRange) = BridgeEnvelope.decode(content) {
        sink.send(event, noteRange: noteRange)
      }
      guard error == nil, !isComplete else {
        connection.cancel()
        return
      }
      receiveNext(on: connection)
    }
  }
}
