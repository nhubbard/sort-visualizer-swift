/// Combines a block's literals buffer with its decoded `(literal_length, offset, match_length)`
/// sequences, appending the reconstructed bytes onto the frame's *cumulative* output — matches
/// can legitimately reference bytes an earlier block in this same frame wrote (the LZ77 window is
/// frame-scoped, not block-scoped; confirmed the hard way, via a real multi-block fixture whose
/// later blocks reference far enough back to only be satisfiable from a prior block's output).
/// Byte-at-a-time copying so overlapping matches (`offset < matchLength`, a run repeating itself)
/// come out correct by construction: appending from `output[matchStart + i]` one byte at a time
/// naturally picks up bytes this same copy already wrote. (The optimized wildcopy/memmove version
/// of this is a later milestone.)
enum SequenceExecutor {
  static func execute(
    literals: [UInt8], sequences: [DecodedSequence], into output: inout [UInt8], limits: ZstdDecodingLimits
  ) throws {
    var literalsIndex = 0

    for sequence in sequences {
      guard literalsIndex + sequence.literalLength <= literals.count else {
        throw ZstdError.invalidSequenceStream
      }
      output.append(contentsOf: literals[literalsIndex..<(literalsIndex + sequence.literalLength)])
      literalsIndex += sequence.literalLength

      if sequence.matchLength > 0 {
        guard sequence.offset >= 1, sequence.offset <= output.count else {
          throw ZstdError.invalidMatchOffset
        }
        let matchStart = output.count - sequence.offset
        output.reserveCapacity(output.count + sequence.matchLength)
        for i in 0..<sequence.matchLength {
          output.append(output[matchStart + i])
        }
      }

      guard output.count <= limits.maximumOutputSize else {
        throw ZstdError.outputLimitExceeded(requested: output.count, limit: limits.maximumOutputSize)
      }
    }

    // Any literals left over after the last sequence are copied verbatim (RFC 8878 §3.1.1.3.2).
    if literalsIndex < literals.count {
      output.append(contentsOf: literals[literalsIndex...])
    }
  }
}
