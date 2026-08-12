import SortAudioCore

/// Fixed-size, versioned binary wire format for one `SortToneEvent` + `noteRange` pair. No
/// JSON/Codable and no length-prefix framing: every field is fixed-width, so the encoded size never
/// varies — a stream reader just needs to always read exactly `encodedByteCount` bytes per message.
/// Big-endian throughout, independent of either end's native endianness (both ends currently run on
/// the same architecture, but this is cheap to get right now and easy to regret skipping later).
enum BridgeWireCodec {
  static let version: UInt8 = 1
  /// version(1) + value/range.lowerBound/range.upperBound/noteRange.lowerBound/noteRange.upperBound
  /// (5 × Int64) + holdSeconds (Double's bit pattern, as UInt64).
  static let encodedByteCount = 1 + 5 * 8 + 8

  static func encode(_ event: SortToneEvent, noteRange: ClosedRange<Int>) -> [UInt8] {
    var bytes: [UInt8] = [version]
    bytes.reserveCapacity(encodedByteCount)
    appendInt64(Int64(event.value), to: &bytes)
    appendInt64(Int64(event.range.lowerBound), to: &bytes)
    appendInt64(Int64(event.range.upperBound), to: &bytes)
    appendInt64(Int64(noteRange.lowerBound), to: &bytes)
    appendInt64(Int64(noteRange.upperBound), to: &bytes)
    appendUInt64(event.holdSeconds.bitPattern, to: &bytes)
    return bytes
  }

  static func decode(_ bytes: some Collection<UInt8>) -> (event: SortToneEvent, noteRange: ClosedRange<Int>)? {
    guard bytes.count == encodedByteCount, bytes.first == version else { return nil }
    let bytes = Array(bytes)
    var offset = 1
    let value = Int(readInt64(bytes, at: &offset))
    let rangeLower = Int(readInt64(bytes, at: &offset))
    let rangeUpper = Int(readInt64(bytes, at: &offset))
    let noteRangeLower = Int(readInt64(bytes, at: &offset))
    let noteRangeUpper = Int(readInt64(bytes, at: &offset))
    let holdSeconds = Double(bitPattern: readUInt64(bytes, at: &offset))
    guard rangeLower <= rangeUpper, noteRangeLower <= noteRangeUpper else { return nil }
    let event = SortToneEvent(value: value, range: rangeLower...rangeUpper, holdSeconds: holdSeconds)
    return (event, noteRangeLower...noteRangeUpper)
  }

  private static func appendInt64(_ value: Int64, to bytes: inout [UInt8]) {
    appendUInt64(UInt64(bitPattern: value), to: &bytes)
  }

  private static func appendUInt64(_ value: UInt64, to bytes: inout [UInt8]) {
    for shift in stride(from: 56, through: 0, by: -8) {
      bytes.append(UInt8((value >> shift) & 0xFF))
    }
  }

  private static func readInt64(_ bytes: [UInt8], at offset: inout Int) -> Int64 {
    Int64(bitPattern: readUInt64(bytes, at: &offset))
  }

  private static func readUInt64(_ bytes: [UInt8], at offset: inout Int) -> UInt64 {
    var value: UInt64 = 0
    for i in 0..<8 {
      value = (value << 8) | UInt64(bytes[offset + i])
    }
    offset += 8
    return value
  }
}
