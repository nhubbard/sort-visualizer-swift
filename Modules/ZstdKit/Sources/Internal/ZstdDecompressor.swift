import Foundation

/// Orchestrates a full frame decode: header, then the block loop, then the trailing content
/// checksum if present. `.compressed` blocks are wired in as literals/sequences support lands
/// (see `COMPRESSION_AND_STRETCH_GOALS_PLAN.md`'s staged decoder milestones).
enum ZstdDecompressor {
  static func decompress(_ data: Data, limits: ZstdDecodingLimits) throws -> Data {
    guard data.count <= limits.maximumFrameSize else {
      throw ZstdError.frameSizeExceeded(requested: data.count, limit: limits.maximumFrameSize)
    }

    var reader = ByteReader([UInt8](data))
    let header = try FrameHeaderParser.parse(&reader, limits: limits)

    var output: [UInt8] = []
    if let frameContentSize = header.frameContentSize {
      output.reserveCapacity(frameContentSize)
    }

    var blockCount = 0
    var isLastBlock = false
    while !isLastBlock {
      blockCount += 1
      guard blockCount <= limits.maximumBlockCount else {
        throw ZstdError.blockCountExceeded(limit: limits.maximumBlockCount)
      }

      let blockHeader = try BlockHeaderParser.parse(&reader)
      isLastBlock = blockHeader.isLastBlock

      switch blockHeader.blockType {
      case .raw:
        output.append(contentsOf: try reader.readBytes(blockHeader.blockSize))
      case .rle:
        let byte = try reader.readByte()
        output.append(contentsOf: repeatElement(byte, count: blockHeader.blockSize))
      case .compressed:
        throw ZstdError.unsupportedFrameFeature("compressed blocks are not implemented yet")
      }

      guard output.count <= limits.maximumOutputSize else {
        throw ZstdError.outputLimitExceeded(requested: output.count, limit: limits.maximumOutputSize)
      }
    }

    if let frameContentSize = header.frameContentSize, output.count != frameContentSize {
      throw ZstdError.contentSizeMismatch(expected: frameContentSize, actual: output.count)
    }

    if header.contentChecksumFlag {
      // XXH64 verification is a separate milestone; consuming these 4 bytes here keeps frame-length
      // accounting (and the trailing-data check below) correct in the meantime.
      _ = try reader.readBytes(4)
    }

    guard reader.remaining == 0 else {
      throw ZstdError.trailingData
    }

    return Data(output)
  }
}
