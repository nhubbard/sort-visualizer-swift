import Foundation
import Network
import SortAudioCore

/// The AU extension's side of the companion-mode bridge: connects to the app's Unix domain socket
/// (inside the shared App Group container) and forwards every received `SortToneEvent` to a
/// `SortAudioEventSink` — in practice a `SortAudioCore.LocalToneEventSink` wrapping the extension's
/// own `ToneRenderer`, reused completely unchanged from the standalone app's local-playback path.
///
/// Retries on a short interval while disconnected, since Logic may instantiate the AU before or
/// after the standalone app is running, in either order, and the app may quit/relaunch at any time
/// while the AU stays loaded on a track.
public final class SortAudioBridgeClient: @unchecked Sendable {
  private let queue = DispatchQueue(label: "com.nhubbard.Sort2.SortAudioBridgeClient")
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
        receiveNext(on: connection)
      case .failed, .cancelled:
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

  /// `minimumIncompleteLength == maximumLength == encodedByteCount` reliably yields exactly one
  /// fixed-size message per call regardless of how the underlying stream happened to chunk the
  /// bytes — `receive` never delivers more than `maximumLength`, and won't complete with fewer
  /// until either that many are available or the connection ends.
  private func receiveNext(on connection: NWConnection) {
    connection.receive(
      minimumIncompleteLength: BridgeWireCodec.encodedByteCount,
      maximumLength: BridgeWireCodec.encodedByteCount
    ) { [weak self] content, _, isComplete, error in
      guard let self else { return }
      if let content, let decoded = BridgeWireCodec.decode(content) {
        sink.send(decoded.event, noteRange: decoded.noteRange)
      }
      guard error == nil, !isComplete else {
        connection.cancel()
        return
      }
      receiveNext(on: connection)
    }
  }
}
