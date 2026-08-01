enum BlockType: UInt8 {
  case raw = 0
  case rle = 1
  case compressed = 2
  // 3 is reserved.
}

/// `Block_Size`'s meaning depends on `blockType`: the literal byte count for `.raw`, the
/// decompressed repeat count for `.rle` (exactly one byte follows in the stream), or the
/// compressed byte count for `.compressed`.
struct BlockHeader {
  let isLastBlock: Bool
  let blockType: BlockType
  let blockSize: Int
}

enum BlockHeaderParser {
  static func parse(_ reader: inout ByteReader) throws -> BlockHeader {
    let raw = try reader.readLittleEndianUInt(byteCount: 3)
    let isLastBlock = (raw & 0x1) == 1
    guard let blockType = BlockType(rawValue: UInt8((raw >> 1) & 0x3)) else {
      throw ZstdError.invalidBlockHeader
    }
    let blockSize = Int((raw >> 3) & 0x1F_FFFF)
    return BlockHeader(isLastBlock: isLastBlock, blockType: blockType, blockSize: blockSize)
  }
}
