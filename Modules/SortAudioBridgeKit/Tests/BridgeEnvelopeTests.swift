import SortAudioCore
import Testing

@testable import SortAudioBridgeKit

@Suite
struct BridgeEnvelopeTests {
  @Test
  func toneEventRoundTrips() {
    let event = SortToneEvent(
      value: 12, range: 0...255, holdSeconds: 0.2, index: 3, arraySize: 255, operationKind: .swap)
    let noteRange = 36...96

    let bytes = BridgeEnvelope.encodeToneEvent(event, noteRange: noteRange)
    #expect(bytes.count == BridgeEnvelope.totalByteCount)

    guard case .toneEvent(let decodedEvent, let decodedNoteRange) = BridgeEnvelope.decode(bytes)
    else {
      Issue.record("expected a toneEvent envelope")
      return
    }
    #expect(decodedEvent == event)
    #expect(decodedNoteRange == noteRange)
  }

  @Test
  func remoteControlCommandRoundTrips() {
    for command in RemoteControlCommand.allCases {
      let bytes = BridgeEnvelope.encodeRemoteControlCommand(command)
      #expect(bytes.count == BridgeEnvelope.totalByteCount)

      guard case .remoteControlCommand(let decoded) = BridgeEnvelope.decode(bytes) else {
        Issue.record("expected a remoteControlCommand envelope for \(command)")
        continue
      }
      #expect(decoded == command)
    }
  }

  @Test
  func decodeRejectsWrongByteCount() {
    #expect(BridgeEnvelope.decode([1]) == nil)
    #expect(
      BridgeEnvelope.decode(Array(repeating: 0, count: BridgeEnvelope.totalByteCount + 1)) == nil)
  }

  @Test
  func decodeRejectsUnknownChannel() {
    var bytes = BridgeEnvelope.encodeRemoteControlCommand(.togglePlayback)
    bytes[0] = 0xFF
    #expect(BridgeEnvelope.decode(bytes) == nil)
  }
}
