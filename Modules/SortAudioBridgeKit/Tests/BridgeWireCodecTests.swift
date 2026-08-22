import SortAudioCore
import Testing

@testable import SortAudioBridgeKit

@Suite
struct BridgeWireCodecTests {
  @Test
  func encodeDecodeRoundTrips() {
    let event = SortToneEvent(
      value: 42, range: 1...256, holdSeconds: 0.125, index: 7, arraySize: 256,
      operationKind: .swap)
    let noteRange = 36...84

    let bytes = BridgeWireCodec.encode(event, noteRange: noteRange)
    #expect(bytes.count == BridgeWireCodec.encodedByteCount)

    let decoded = BridgeWireCodec.decode(bytes)
    #expect(decoded?.event == event)
    #expect(decoded?.noteRange == noteRange)
  }

  @Test
  func decodeRejectsWrongByteCount() {
    #expect(BridgeWireCodec.decode([BridgeWireCodec.version]) == nil)
    #expect(BridgeWireCodec.decode(Array(repeating: 0, count: BridgeWireCodec.encodedByteCount + 1)) == nil)
  }

  @Test
  func decodeRejectsUnknownVersion() {
    var bytes = BridgeWireCodec.encode(
      SortToneEvent(
        value: 1, range: 0...10, holdSeconds: 0.1, index: 0, arraySize: 10,
        operationKind: .compare), noteRange: 36...72)
    bytes[0] = 0xFF
    #expect(BridgeWireCodec.decode(bytes) == nil)
  }

  @Test
  func decodeRejectsInvertedRanges() {
    var bytes = BridgeWireCodec.encode(
      SortToneEvent(
        value: 1, range: 0...10, holdSeconds: 0.1, index: 0, arraySize: 10,
        operationKind: .compare), noteRange: 36...72)
    // Corrupt the range's lower bound (bytes 9...16) to something above its upper bound (10).
    bytes[16] = 99
    #expect(BridgeWireCodec.decode(bytes) == nil)
  }
}
