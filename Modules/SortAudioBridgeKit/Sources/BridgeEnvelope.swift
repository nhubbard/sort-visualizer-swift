import SortAudioCore

/// The fixed-size wire envelope every bridge message uses, in either direction: a 1-byte channel
/// tag followed by a fixed payload slot sized to the larger of the two message shapes —
/// `SortToneEvent` (app → extension) uses all of it via `BridgeWireCodec`; `RemoteControlCommand`
/// (extension → app, the AU-hosted remote) uses one byte of it and pads the rest. Keeping every
/// message the same total size regardless of direction or channel means one fixed-size
/// `receive(minimumIncompleteLength:maximumLength:)` shape suffices on both ends — no
/// length-prefix framing needed, since nothing here is genuinely variable-length.
enum BridgeEnvelope {
  enum Channel: UInt8 {
    case toneEvent = 1
    case remoteControlCommand = 2
  }

  static let payloadByteCount = BridgeWireCodec.encodedByteCount
  static let totalByteCount = 1 + payloadByteCount

  enum Decoded {
    case toneEvent(event: SortToneEvent, noteRange: ClosedRange<Int>)
    case remoteControlCommand(RemoteControlCommand)
  }

  static func encodeToneEvent(_ event: SortToneEvent, noteRange: ClosedRange<Int>) -> [UInt8] {
    [Channel.toneEvent.rawValue] + BridgeWireCodec.encode(event, noteRange: noteRange)
  }

  static func encodeRemoteControlCommand(_ command: RemoteControlCommand) -> [UInt8] {
    [Channel.remoteControlCommand.rawValue, command.rawValue]
      + [UInt8](repeating: 0, count: payloadByteCount - 1)
  }

  static func decode(_ bytes: some Collection<UInt8>) -> Decoded? {
    guard bytes.count == totalByteCount,
      let firstByte = bytes.first,
      let channel = Channel(rawValue: firstByte)
    else { return nil }
    let payload = bytes.dropFirst()

    switch channel {
    case .toneEvent:
      guard let decoded = BridgeWireCodec.decode(payload) else { return nil }
      return .toneEvent(event: decoded.event, noteRange: decoded.noteRange)
    case .remoteControlCommand:
      guard let rawValue = payload.first, let command = RemoteControlCommand(rawValue: rawValue)
      else { return nil }
      return .remoteControlCommand(command)
    }
  }
}
