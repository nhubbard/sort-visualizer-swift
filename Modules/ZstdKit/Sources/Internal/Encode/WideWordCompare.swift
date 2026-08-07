/// The `ZSTD_count` mirror, shared by every match finder in this module (`MatchFinder`'s hash-chain
/// search, `RowHashMatchFinder`'s row-hash search): how many consecutive bytes starting at `a` and
/// `b` agree, via `UInt64` XOR + `trailingZeroBitCount` — a wide-scalar trick, not SIMD (see
/// `COMPRESSION_DESIGN.md`'s honest accounting of where this encoder does and doesn't use real
/// vector hardware). `b < a` always in practice (candidates only ever come from already-inserted,
/// strictly earlier positions), but the byte-level comparison itself is safe (and correct —
/// including the `offset < matchLength` overlapping/self-referential case, e.g. runs of one
/// repeated byte) however far it extends, since `buffer` is a complete, static, already-fully-known
/// array, not a growing output needing copy-on-write aliasing care the way `MatchCopier`'s decode-
/// side output buffer does.
func wideWordMatchLength(in buffer: [UInt8], _ a: Int, _ b: Int) -> Int {
  let limit = buffer.count
  var length = 0
  while a + length + 8 <= limit {
    let wordA = readUInt64LE(buffer, a + length)
    let wordB = readUInt64LE(buffer, b + length)
    let diff = wordA ^ wordB
    if diff != 0 {
      return length + diff.trailingZeroBitCount / 8
    }
    length += 8
  }
  while a + length < limit, buffer[a + length] == buffer[b + length] {
    length += 1
  }
  return length
}

private func readUInt64LE(_ buffer: [UInt8], _ position: Int) -> UInt64 {
  var value: UInt64 = 0
  for index in 0..<8 {
    value |= UInt64(buffer[position + index]) << (8 * index)
  }
  return value
}
