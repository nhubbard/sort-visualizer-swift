// This file's per-symbol code+length lookup mirrors `HuffmanStreamDecoder`'s decode loop in
// reverse. See NOTICE.md.
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

/// Encodes `bytes` into one Huffman-coded stream (single-stream form only — 4-stream is a later
/// optimization, not a correctness requirement). Unlike FSE, Huffman needs no reverse-order
/// processing: `HuffmanStreamDecoder.decode` decodes symbol 0, 1, 2... in a plain forward loop, so
/// pushing symbols in their normal order here — the same order `BackwardBitWriter`'s own contract
/// already guarantees ("push order = decode order") — is exactly correct.
enum HuffmanStreamEncoder {
  static func encode(_ bytes: [UInt8], table: HuffmanEncodeTable) -> [UInt8]? {
    var writer = BackwardBitWriter()
    for byte in bytes {
      guard let huffmanCode = table.codes[Int(byte)] else { return nil }
      writer.writeBits(UInt32(huffmanCode.code), count: huffmanCode.nbBits)
    }
    return writer.finish()
  }
}
