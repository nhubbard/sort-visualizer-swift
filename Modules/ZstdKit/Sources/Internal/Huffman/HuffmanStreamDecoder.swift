enum HuffmanStreamDecoder {
  /// Decodes exactly `count` symbols from one Huffman-coded bitstream: peek `maxBits` bits as a
  /// LUT index, look up `(symbol, nbBits)`, emit the symbol, consume only `nbBits`.
  static func decode(_ bytes: ArraySlice<UInt8>, count: Int, table: HuffmanDecodeTable) throws -> [UInt8] {
    guard count > 0 else { return [] }
    var reader = try BackwardBitReader(Array(bytes))
    var output = [UInt8]()
    output.reserveCapacity(count)
    for _ in 0..<count {
      let index = Int(reader.peekBits(table.maxBits))
      guard index < table.symbolOf.count else { throw ZstdError.invalidHuffmanTable }
      output.append(table.symbolOf[index])
      _ = reader.readBits(Int(table.numberOfBits[index]))
    }
    return output
  }
}
