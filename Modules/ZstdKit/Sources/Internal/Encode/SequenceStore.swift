/// One parsed `(literal_length, offset, match_length)` triple, pre-code-selection — the encode-
/// direction counterpart to `DecodedSequence`.
struct RawSequence {
  let literalLength: Int
  let offset: Int
  let matchLength: Int
}

/// A block's LZ77 parse: every literal byte (from every sequence's preceding run, plus any
/// trailing bytes after the last match — `SequenceExecutor`'s own "copied verbatim" tail,
/// mirrored here on the encode side) concatenated in order, and the sequences themselves.
struct SequenceStore {
  let literals: [UInt8]
  let sequences: [RawSequence]
}

enum BlockParser {
  /// Runs the greedy match finder across the whole chunk, threading a single "pending literal
  /// run" cursor forward — matches are accepted eagerly (no lookahead), and every position gets
  /// inserted into the match finder's hash table regardless of whether it ends up inside a literal
  /// run or a match, so a later position can still reference it.
  static func parse(_ chunk: [UInt8], options: ZstdEncodingOptions) -> SequenceStore {
    guard chunk.count >= 8 else {
      return SequenceStore(literals: chunk, sequences: [])
    }

    let hashLog = min(options.hashLog, 17)
    let finder = MatchFinder(input: chunk, hashLog: hashLog)
    var literals: [UInt8] = []
    var sequences: [RawSequence] = []
    var literalStart = 0
    var ip = 0
    let limit = chunk.count

    while ip + 4 <= limit {
      if let match = finder.findBestMatch(
        at: ip, minMatch: options.minimumMatchLength, maxAttempts: options.maximumSearchAttempts)
      {
        literals.append(contentsOf: chunk[literalStart..<ip])
        sequences.append(
          RawSequence(literalLength: ip - literalStart, offset: ip - match.position, matchLength: match.length))
        ip += match.length
        literalStart = ip
      } else {
        ip += 1
      }
    }

    literals.append(contentsOf: chunk[literalStart...])
    return SequenceStore(literals: literals, sequences: sequences)
  }
}
