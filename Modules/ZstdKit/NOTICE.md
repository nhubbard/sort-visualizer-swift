# Notice

`ZstdKit` is a from-scratch Swift port of a subset of [Zstandard](https://github.com/facebook/zstd)'s
decoding *and* encoding algorithms (frame/block parsing and construction, FSE table decode/encode,
Huffman literals decode/encode, FSE-coded sequences decode/encode, LZ77 execution and a greedy
hash-chain match finder) and of [xxHash](https://github.com/Cyan4973/xxHash)'s XXH64 checksum, which
ships as part of the Zstandard source tree. See `COMPRESSION_DESIGN.md` for the full design
rationale — the encoder (`Sources/Internal/Encode/`, `Sources/Internal/FSE/FSEEncodeTable.swift`,
`Sources/Internal/Huffman/HuffmanEncodeTable.swift`/`HuffmanStreamEncoder.swift`,
`Sources/Internal/Sequences/SequenceCodeSelection.swift`/`SequenceStreamEncoder.swift`) is the same
BSD-licensed reference source transcribed in the write direction, with the same "logic transcribed,
no C linked" model as the decoder.

No C/C++ source is linked, vendored, or transpiled — every file is original Swift. But the *logic*
throughout this module (bitstream conventions, table-construction algorithms, decode-loop
structure, sequence/offset-resolution rules, and — in `XXH64.swift` and the sequence baseline/
extra-bits tables — the numeric constants themselves) is transcribed or closely adapted from the
reference `zstd`/`xxHash` C source and cross-checked against real `zstd`-produced output, not
derived solely from the RFC 8878 prose. Each source file under `Sources/` carries a short note on
what it specifically reuses.

Reused under the BSD License, from Zstandard (`github.com/facebook/zstd`, `LICENSE`) and xxHash
(bundled in the same repository under `lib/common/xxhash.h`/`xxhash.c`):

```
BSD License

For Zstandard software

Copyright (c) Meta Platforms, Inc. and affiliates. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

 * Neither the name Facebook, nor Meta, nor the names of its contributors may
   be used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

`xxhash.h`'s own header additionally credits its original author directly
(`Copyright (c) Yann Collet - Meta Platforms, Inc`) under the same dual BSD/GPLv2 license offered by
the Zstandard repository it ships in; `XXH64.swift` carries that attribution specifically. Zstandard
itself is dual-licensed BSD/GPLv2 — this project selects the BSD option, as permitted by
`zstd`'s own license file ("You may select, at your option, one of the above-listed licenses").
