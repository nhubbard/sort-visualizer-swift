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
  /// `initialRepeatOffset` is the frame's current `offset1` (`EncodeRepeatOffsets.offset1`) at the
  /// point this chunk starts — read-only here, purely to let `options.searchDepth >= 1`'s lazy
  /// driver cheaply check rep-code matches during lookahead; no offset-state mutation happens
  /// during parsing (that's still `SequenceStreamEncoder.encode`'s job, unchanged).
  static func parse(
    _ chunk: [UInt8], initialRepeatOffset: Int = 1, options: ZstdEncodingOptions
  ) -> SequenceStore {
    guard chunk.count >= 8 else {
      return SequenceStore(literals: chunk, sequences: [])
    }
    if options.searchDepth == 0 {
      return parseGreedy(chunk, options: options)
    }
    return parseLazy(chunk, initialRepeatOffset: initialRepeatOffset, options: options)
  }

  /// Runs the greedy match finder across the whole chunk, threading a single "pending literal
  /// run" cursor forward — matches are accepted eagerly (no lookahead), and every position gets
  /// inserted into the match finder's hash table regardless of whether it ends up inside a literal
  /// run or a match, so a later position can still reference it. Exactly this module's Phase 1
  /// behavior, kept byte-for-byte unchanged as `options.searchDepth == 0`'s code path.
  private static func parseGreedy(_ chunk: [UInt8], options: ZstdEncodingOptions) -> SequenceStore {
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

  /// Ported from `ZSTD_compressBlock_lazy_generic` (`zstd_lazy.c`): after finding a baseline
  /// candidate at `ip`, keep re-searching one position ahead (and, at `searchDepth == 2`, one
  /// position further still) for as long as the new candidate's *gain* — `matchLength * K -
  /// highbit32(offBase) + bias`, log-scaling the offset as a proxy for its coding cost — beats the
  /// one currently held. `K`/`bias` constants are the exact ones the reference source uses (not
  /// approximated): `K=3` comparing a cheap repeat-offset check against the current best, `K=4`
  /// comparing a fresh hash-table search; `bias` starts at `0` for the very first pick and grows
  /// (`1`/`4` at depth 1, `1`/`7` at depth 2) to make each successive lookahead round progressively
  /// harder to win — the hysteresis that keeps lazy matching from degenerating into unbounded
  /// lookahead. Every visited position — whether its round wins or not — gets a real
  /// `findBestMatch` call, so every one of them lands in the hash table for later searches, exactly
  /// matching the reference's own insert-on-visit guarantee.
  private static func parseLazy(
    _ chunk: [UInt8], initialRepeatOffset: Int, options: ZstdEncodingOptions
  ) -> SequenceStore {
    let hashLog = min(options.hashLog, 17)
    let finder = MatchFinder(input: chunk, hashLog: hashLog)
    var literals: [UInt8] = []
    var sequences: [RawSequence] = []
    var literalStart = 0
    var ip = 0
    let limit = chunk.count
    let offset1 = initialRepeatOffset

    func repMatchLength(at position: Int) -> Int {
      guard offset1 > 0, position - offset1 >= 0 else { return 0 }
      return wideWordMatchLength(in: chunk, position, position - offset1)
    }
    func gain(_ matchLength: Int, _ offBase: Int, k: Int, bias: Int) -> Int {
      let highbit = 31 - UInt32(offBase).leadingZeroBitCount
      return matchLength * k - highbit + bias
    }

    while ip + 4 <= limit {
      let baselineSearch = finder.findBestMatch(
        at: ip, minMatch: options.minimumMatchLength, maxAttempts: options.maximumSearchAttempts)
      let baselineRep = repMatchLength(at: ip)

      var matchStart = ip
      var matchPosition = -1
      var matchLength = 0
      var offBase = 0

      if baselineRep >= options.minimumMatchLength, let baselineSearch,
        gain(baselineRep, 1, k: 3, bias: 0)
          > gain(baselineSearch.length, ip - baselineSearch.position + 3, k: 3, bias: 0)
      {
        matchPosition = ip - offset1
        matchLength = baselineRep
        offBase = 1
      } else if let baselineSearch {
        matchPosition = baselineSearch.position
        matchLength = baselineSearch.length
        offBase = ip - baselineSearch.position + 3
      } else if baselineRep >= options.minimumMatchLength {
        matchPosition = ip - offset1
        matchLength = baselineRep
        offBase = 1
      }

      guard matchLength > 0 else {
        ip += 1
        continue
      }

      outer: while options.searchDepth >= 1, matchStart + 1 + 4 <= limit {
        let round1Position = matchStart + 1
        let round1Rep = repMatchLength(at: round1Position)
        let round1Search = finder.findBestMatch(
          at: round1Position, minMatch: options.minimumMatchLength,
          maxAttempts: options.maximumSearchAttempts)

        if round1Rep >= options.minimumMatchLength,
          gain(round1Rep, 1, k: 3, bias: 1) > gain(matchLength, offBase, k: 3, bias: 0)
        {
          matchStart = round1Position
          matchPosition = round1Position - offset1
          matchLength = round1Rep
          offBase = 1
          continue outer
        } else if let round1Search,
          gain(round1Search.length, round1Position - round1Search.position + 3, k: 4, bias: 4)
            > gain(matchLength, offBase, k: 4, bias: 0)
        {
          matchStart = round1Position
          matchPosition = round1Search.position
          matchLength = round1Search.length
          offBase = round1Position - round1Search.position + 3
          continue outer
        }

        if options.searchDepth >= 2, round1Position + 1 + 4 <= limit {
          let round2Position = round1Position + 1
          let round2Rep = repMatchLength(at: round2Position)
          let round2Search = finder.findBestMatch(
            at: round2Position, minMatch: options.minimumMatchLength,
            maxAttempts: options.maximumSearchAttempts)

          if round2Rep >= options.minimumMatchLength,
            gain(round2Rep, 1, k: 4, bias: 1) > gain(matchLength, offBase, k: 4, bias: 0)
          {
            matchStart = round2Position
            matchPosition = round2Position - offset1
            matchLength = round2Rep
            offBase = 1
            continue outer
          } else if let round2Search,
            gain(round2Search.length, round2Position - round2Search.position + 3, k: 4, bias: 7)
              > gain(matchLength, offBase, k: 4, bias: 0)
          {
            matchStart = round2Position
            matchPosition = round2Search.position
            matchLength = round2Search.length
            offBase = round2Position - round2Search.position + 3
            continue outer
          }
        }

        break outer
      }

      // Backward extension: recover literal bytes lookahead left stranded in the pending run,
      // by extending the match earlier for as long as the bytes right before it still agree.
      while matchStart > literalStart, matchPosition > 0,
        chunk[matchStart - 1] == chunk[matchPosition - 1]
      {
        matchStart -= 1
        matchPosition -= 1
        matchLength += 1
      }

      literals.append(contentsOf: chunk[literalStart..<matchStart])
      sequences.append(
        RawSequence(
          literalLength: matchStart - literalStart, offset: matchStart - matchPosition,
          matchLength: matchLength))
      ip = matchStart + matchLength
      literalStart = ip
    }

    literals.append(contentsOf: chunk[literalStart...])
    return SequenceStore(literals: literals, sequences: sequences)
  }
}
