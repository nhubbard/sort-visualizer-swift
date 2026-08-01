// This module ports a subset of Zstandard's decoding algorithm (RFC 8878) from the real
// `zstd` C source; these error cases mirror the distinct failure categories the reference
// decoder itself distinguishes. See NOTICE.md.
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

/// Errors a `Zstd.decompress` call can throw. Every structural or memory-safety condition the
/// decoder checks throws one of these in release builds — none of it is gated behind `assert`.
public enum ZstdError: Error, Sendable, Equatable {
  case invalidMagic
  case unsupportedFrameFeature(String)
  case unsupportedWindowSize(requested: Int, limit: Int)
  case frameSizeExceeded(requested: Int, limit: Int)
  case outputLimitExceeded(requested: Int, limit: Int)
  case blockCountExceeded(limit: Int)
  case truncatedInput
  case invalidFrameHeader
  case invalidBlockHeader
  case contentSizeMismatch(expected: Int, actual: Int)
  case invalidLiteralsSection
  case invalidHuffmanTable
  case invalidFSETable
  case invalidBitstream
  case invalidSequenceStream
  case invalidMatchOffset
  case dictionaryRequired(id: UInt32)
  case dictionaryIDMismatch(expected: UInt32, actual: UInt32)
  case checksumMismatch
  case trailingData
}
