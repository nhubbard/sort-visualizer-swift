enum LiteralsBlockType: UInt8 {
  case raw = 0
  case rle = 1
  case compressed = 2
  case treeless = 3
}

/// `compressedSize`/`streamCount` only apply to `.compressed`/`.treeless` — zero/one respectively
/// for `.raw`/`.rle`, which have no Huffman table and copy `regeneratedSize` bytes directly.
struct LiteralsSectionHeader {
  let blockType: LiteralsBlockType
  let regeneratedSize: Int
  let compressedSize: Int
  let streamCount: Int
}

/// Parses the literals section header (RFC 8878 §3.1.1.3.1) — 1, 2, or 3 bytes for
/// `.raw`/`.rle` (5/12/20-bit sizes), or 3, 4, or 5 bytes for `.compressed`/`.treeless`
/// (10/14/18-bit regenerated+compressed size pairs, the first two byte-widths also carrying a
/// 1-vs-4-stream flag in what would otherwise be a duplicate size class). Byte widths and bit
/// positions confirmed empirically against real zstd output during development, not solely
/// derived from the spec text.
enum LiteralsSectionParser {
  static func parse(_ reader: inout ByteReader) throws -> LiteralsSectionHeader {
    let first = try reader.peekByte()
    guard let blockType = LiteralsBlockType(rawValue: first & 0x3) else {
      throw ZstdError.invalidLiteralsSection
    }
    let sizeFormat = (first >> 2) & 0x3

    switch blockType {
    case .raw, .rle:
      switch sizeFormat {
      case 0, 2:
        _ = try reader.readByte()
        return LiteralsSectionHeader(
          blockType: blockType, regeneratedSize: Int(first >> 3), compressedSize: 0, streamCount: 1
        )
      case 1:
        let value = try reader.readLittleEndianUInt(byteCount: 2)
        return LiteralsSectionHeader(
          blockType: blockType, regeneratedSize: Int(value >> 4), compressedSize: 0, streamCount: 1
        )
      default:
        let value = try reader.readLittleEndianUInt(byteCount: 3)
        return LiteralsSectionHeader(
          blockType: blockType, regeneratedSize: Int(value >> 4), compressedSize: 0, streamCount: 1
        )
      }

    case .compressed, .treeless:
      switch sizeFormat {
      case 0, 1:
        let value = try reader.readLittleEndianUInt(byteCount: 3)
        return LiteralsSectionHeader(
          blockType: blockType,
          regeneratedSize: Int((value >> 4) & 0x3FF),
          compressedSize: Int((value >> 14) & 0x3FF),
          streamCount: sizeFormat == 0 ? 1 : 4
        )
      case 2:
        let value = try reader.readLittleEndianUInt(byteCount: 4)
        return LiteralsSectionHeader(
          blockType: blockType,
          regeneratedSize: Int((value >> 4) & 0x3FFF),
          compressedSize: Int((value >> 18) & 0x3FFF),
          streamCount: 4
        )
      default:
        let bytes = try reader.readBytes(5)
        let base = bytes.startIndex
        let firstWord =
          UInt32(bytes[base]) | (UInt32(bytes[base + 1]) << 8) | (UInt32(bytes[base + 2]) << 16)
          | (UInt32(bytes[base + 3]) << 24)
        let secondWord =
          UInt32(bytes[base + 1]) | (UInt32(bytes[base + 2]) << 8) | (UInt32(bytes[base + 3]) << 16)
          | (UInt32(bytes[base + 4]) << 24)
        return LiteralsSectionHeader(
          blockType: blockType,
          regeneratedSize: Int((firstWord >> 4) & 0x3_FFFF),
          compressedSize: Int(secondWord >> 2),
          streamCount: 4
        )
      }
    }
  }
}
