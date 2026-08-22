// This module ports a subset of Zstandard's decoding algorithm (RFC 8878) from the real
// `zstd` C source; these limits mirror the resource ceilings the reference decoder itself
// enforces (window size, frame size, block count). See NOTICE.md.
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

/// Resource ceilings the decoder enforces before trusting a frame's own declared sizes. Sized
/// comfortably above any real archive this app ships but low enough to reject a corrupted or
/// hostile declaration before it drives an allocation.
public struct ZstdDecodingLimits: Sendable, Equatable {
  public var maximumOutputSize: Int
  public var maximumWindowSize: Int
  public var maximumDictionarySize: Int
  public var maximumBlockCount: Int
  public var maximumFrameSize: Int

  public init(
    maximumOutputSize: Int = 1 << 30,
    maximumWindowSize: Int = 1 << 27,
    maximumDictionarySize: Int = 1 << 25,
    maximumBlockCount: Int = 1 << 20,
    maximumFrameSize: Int = 1 << 30
  ) {
    self.maximumOutputSize = maximumOutputSize
    self.maximumWindowSize = maximumWindowSize
    self.maximumDictionarySize = maximumDictionarySize
    self.maximumBlockCount = maximumBlockCount
    self.maximumFrameSize = maximumFrameSize
  }

  public static let `default` = ZstdDecodingLimits()
}
