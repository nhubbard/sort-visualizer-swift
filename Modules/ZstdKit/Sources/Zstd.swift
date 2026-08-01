// This module's public API is original, but the decoder it fronts ports a subset of
// Zstandard's decoding algorithm (RFC 8878) from the real `zstd`/`xxHash` C source. See
// NOTICE.md.
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

import Foundation

/// A from-scratch, decode-only Zstandard implementation — no C/C++ interop. Encoding is
/// permanently out of scope; the Python content pipeline (`App/Resources/AlgorithmDetails/manage.py`)
/// is the sole encoder. See `COMPRESSION_AND_STRETCH_GOALS_PLAN.md` for the full design rationale.
public enum Zstd {
  /// Decompresses one standard Zstd frame. Concatenated frames, skippable frames, legacy formats,
  /// and magicless framing are rejected with a specific `ZstdError`, not misclassified as corrupt
  /// data. Dictionary support is not yet part of this API — frames requiring one throw
  /// `.dictionaryRequired`.
  public static func decompress(
    _ frame: Data,
    limits: ZstdDecodingLimits = .default
  ) throws -> Data {
    try ZstdDecompressor.decompress(frame, limits: limits)
  }
}
