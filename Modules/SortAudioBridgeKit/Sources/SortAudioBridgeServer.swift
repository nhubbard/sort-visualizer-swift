import Foundation
import Network
import SortAudioCore

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
  private var listener: NWListener?
  private var connections: [ObjectIdentifier: NWConnection] = [:]

  public init() {}

  /// Whether at least one AU instance is currently connected — `AudioService` reads this to decide
  /// whether to route audio through the bridge (replacing local playback) or play locally as usual.
  public var hasConnectedClients: Bool {
    queue.sync { !connections.isEmpty }
  }

  /// `socketPath` should come from `SortAudioBridgePath.socketPath()` — a plain path outside the
  /// App Group container won't be reachable from the sandboxed AU extension process.
  public func start(socketPath: String) throws {
    let params = NWParameters()
    params.defaultProtocolStack.transportProtocol = NWProtocolTCP.Options()
    params.requiredLocalEndpoint = .unix(path: socketPath)
    params.allowLocalEndpointReuse = true

    // A stale socket file from a previous run (crash, force-quit) makes the bind fail — Unix
    // sockets don't clean up their filesystem entry on their own.
    try? FileManager.default.removeItem(atPath: socketPath)

    let listener = try NWListener(using: params)
    listener.newConnectionHandler = { [weak self] connection in
      self?.accept(connection)
    }
    listener.start(queue: queue)
    self.listener = listener
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
    let data = Data(BridgeWireCodec.encode(event, noteRange: noteRange))
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
      case .failed, .cancelled:
        self?.connections.removeValue(forKey: id)
      default:
        break
      }
    }
    connections[id] = connection
    connection.start(queue: queue)
  }
}
