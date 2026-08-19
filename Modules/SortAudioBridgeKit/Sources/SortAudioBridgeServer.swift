import Foundation
import Network
import SortAudioCore
import os

/// The standalone app's side of the companion-mode bridge: binds a Unix domain socket inside the
/// shared App Group container and broadcasts every `SortToneEvent` to whichever AU extension
/// instance(s) are currently connected. One connection per AU instance (e.g. one per Logic Pro
/// track) — fanning a single broadcast out to every connected client comes for free from this
/// shape, no extra design needed for the multi-instance case.
///
/// All mutable state (`listener`, `connections`) is only ever touched on `queue` — including from
/// `broadcast(_:noteRange:)`, which dispatches onto `queue` and reads `self.connections` from
/// *inside* that closure rather than capturing it at the call site, so a call arriving on any
/// thread (this type is `@unchecked Sendable`) can't race a connection being added/removed.
public final class SortAudioBridgeServer: @unchecked Sendable {
  private let queue = DispatchQueue(label: "com.nhubbard.Sort2.SortAudioBridgeServer")
  private let logger = Logger(subsystem: "com.nhubbard.Sort2.SortAudioBridgeKit", category: "SortAudioBridgeServer")
  private var listener: NWListener?
  private var connections: [ObjectIdentifier: NWConnection] = [:]

  /// Fires on an arbitrary background queue whenever the connected-client count transitions to/from
  /// zero — `AudioService` uses this to drive a UI-visible connection indicator. Callers needing
  /// this on the main actor must hop themselves.
  public var onConnectedClientsChanged: (@Sendable (Bool) -> Void)?

  /// Fires on an arbitrary background queue whenever the listener itself changes state — distinct
  /// from `onConnectedClientsChanged`, since "bound and listening, nothing connected yet" and
  /// "failed to bind at all" (e.g. a sandbox/entitlement problem) are different situations a UI
  /// status indicator should be able to tell apart.
  public var onListenerStateChanged: (@Sendable (ListenerState) -> Void)?

  /// Fires on an arbitrary background queue whenever a connected AU instance sends a remote-control
  /// command (the AU-hosted transport remote, Documentation/docs/architecture/audio.md) — `AudioService` forwards
  /// this to whatever's driving the currently-active `SortSession`.
  public var onRemoteControlCommandReceived: (@Sendable (RemoteControlCommand) -> Void)?

  public enum ListenerState: Sendable, Equatable {
    case listening
    case failed
    case cancelled
  }

  public init() {}

  /// Whether at least one AU instance is currently connected — `AudioService` reads this to decide
  /// whether to route audio through the bridge (replacing local playback) or play locally as usual.
  public var hasConnectedClients: Bool {
    queue.sync { !connections.isEmpty }
  }

  /// `socketPath` should come from `SortAudioBridgePath.socketPath()` — a plain path outside the
  /// App Group container won't be reachable from the sandboxed AU extension process. The `throw`
  /// here only covers gross parameter errors (e.g. a malformed endpoint) — an actual bind failure
  /// (permission denied, sandbox violation) surfaces asynchronously via `listener.stateUpdateHandler`
  /// below instead, which is why that handler logs rather than assuming a thrown error would catch
  /// every failure mode.
  public func start(socketPath: String) throws {
    let params = NWParameters()
    params.defaultProtocolStack.transportProtocol = NWProtocolTCP.Options()
    params.requiredLocalEndpoint = .unix(path: socketPath)
    params.allowLocalEndpointReuse = true

    // A stale socket file from a previous run (crash, force-quit) makes the bind fail — Unix
    // sockets don't clean up their filesystem entry on their own.
    try? FileManager.default.removeItem(atPath: socketPath)

    let listener = try NWListener(using: params)
    listener.stateUpdateHandler = { [weak self] state in
      switch state {
      case .ready:
        self?.logger.info("listening at \(socketPath, privacy: .public)")
        self?.onListenerStateChanged?(.listening)
      case .failed(let error):
        self?.logger.error("failed to bind at \(socketPath, privacy: .public): \(String(describing: error), privacy: .public)")
        self?.onListenerStateChanged?(.failed)
      case .waiting(let error):
        self?.logger.notice("waiting to bind at \(socketPath, privacy: .public): \(String(describing: error), privacy: .public)")
      case .cancelled:
        self?.logger.debug("listener cancelled")
        self?.onListenerStateChanged?(.cancelled)
      default:
        break
      }
    }
    listener.newConnectionHandler = { [weak self] connection in
      self?.accept(connection)
    }
    listener.start(queue: queue)
    self.listener = listener
    logger.info("starting bridge server, socket path: \(socketPath, privacy: .public)")
  }

  public func stop() {
    queue.sync {
      listener?.cancel()
      listener = nil
      for connection in connections.values { connection.cancel() }
      connections.removeAll()
    }
  }

  public func broadcast(_ event: SortToneEvent, noteRange: ClosedRange<Int>) {
    let data = Data(BridgeEnvelope.encodeToneEvent(event, noteRange: noteRange))
    queue.async { [weak self] in
      guard let self else { return }
      for connection in self.connections.values {
        connection.send(content: data, completion: .idempotent)
      }
    }
  }

  /// Runs on `queue` already — `listener.start(queue:)` guarantees `newConnectionHandler` fires on
  /// the queue it was started with.
  private func accept(_ connection: NWConnection) {
    let id = ObjectIdentifier(connection)
    connection.stateUpdateHandler = { [weak self] state in
      switch state {
      case .ready:
        self?.logger.info("AU client connected")
      case .failed(let error):
        self?.logger.error("AU client connection failed: \(String(describing: error), privacy: .public)")
        self?.removeConnection(id)
      case .cancelled:
        self?.removeConnection(id)
      default:
        break
      }
    }
    connections[id] = connection
    connection.start(queue: queue)
    notifyConnectedClientsChanged()
    receiveNext(on: connection)
  }

  /// The server was write-only before the AU remote existed — this is its first receive path.
  /// Reads whatever a connected AU instance sends back (only remote-control commands today; a
  /// stray `toneEvent` channel byte from a client would just be ignored, not crash anything).
  private func receiveNext(on connection: NWConnection) {
    connection.receive(
      minimumIncompleteLength: BridgeEnvelope.totalByteCount,
      maximumLength: BridgeEnvelope.totalByteCount
    ) { [weak self] content, _, isComplete, error in
      guard let self else { return }
      if let content, case .remoteControlCommand(let command) = BridgeEnvelope.decode(content) {
        self.onRemoteControlCommandReceived?(command)
      }
      guard error == nil, !isComplete else { return }
      self.receiveNext(on: connection)
    }
  }

  /// Runs on `queue` already, same reasoning as `accept(_:)` — both call sites are connection
  /// state-update handlers, which fire on the queue the connection was started with.
  private func removeConnection(_ id: ObjectIdentifier) {
    connections.removeValue(forKey: id)
    notifyConnectedClientsChanged()
  }

  private func notifyConnectedClientsChanged() {
    onConnectedClientsChanged?(!connections.isEmpty)
  }
}
