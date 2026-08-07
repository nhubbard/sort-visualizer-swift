import CryptoKit
import Foundation
import ZstdKit

/// Binary export/import for a recorded (or replayed, or imported) `Tape` — a self-contained
/// archive format modeled on `AlgorithmDetails.algz`'s envelope shape, built on `ZstdKit`'s own
/// encoder/decoder. `ReplayEngine(tape:)` takes a plain `Tape` with zero provenance opinion, so
/// nothing downstream needs to know a tape came from a file rather than a live recording.
extension Tape {
  public func archived() throws -> Data {
    let payload = TapeArchivePayload.encode(self)
    let digest = SHA256.hash(data: Data(payload))
    let compressed = try Zstd.compress(Data(payload))
    let bytes = TapeArchiveEnvelope.write(
      frame: Array(compressed), decompressedLength: payload.count, sha256: Array(digest))
    return Data(bytes)
  }

  public init(archivedData: Data) throws {
    let bytes = Array(archivedData)
    let envelope = try TapeArchiveEnvelope.parse(bytes)
    let frameBytes = Array(bytes[envelope.frameRange])
    let decompressed = try Zstd.decompress(Data(frameBytes))
    guard decompressed.count == envelope.decompressedLength else {
      throw TapeArchiveError.invalidSectionRange
    }
    let digest = SHA256.hash(data: decompressed)
    guard Array(digest) == envelope.sha256 else { throw TapeArchiveError.hashMismatch }
    self = try TapeArchivePayload.decode(Array(decompressed))
  }
}
