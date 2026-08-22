// This file's peek/consume Huffman decode loop matches the real `zstd` C source's
// `HUF_decodeSymbolX1` flat-LUT approach. See NOTICE.md.
//
// Used under the BSD License:
//
// BSD License
//
// For Zstandard software
//
// Copyright (c) Meta Platforms, Inc. and affiliates. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  * Neither the name Facebook, nor Meta, nor the names of its contributors may
//    be used to endorse or promote products derived from this software without
//    specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
