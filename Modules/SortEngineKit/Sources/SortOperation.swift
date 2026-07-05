/// A single logical step an algorithm performs against a `RecordingEngine`. A `Tape` is nothing
/// more than an ordered array of these — replaying them one at a time is the entire mechanism
/// behind stepping, scrubbing, and speed control (§1 of ARCHITECTURE_V2.md).
public enum SortOperation: Sendable, Codable, Equatable {
    case swap(Int, Int)
    case setValue(Int, Int)
    /// ArrayV-style: persists on `index` until `.unmark`/`.unmarkAll` clears it.
    case mark(marker: Int, index: Int)
    case unmark(marker: Int)
    case unmarkAll
    /// Counted, structurally inert — never changes `values`.
    case compare(Int, Int)
    /// Permanent "done" marker at completion.
    case markSorted(Int)
    case auxCreate(handle: Int, length: Int)
    case auxWrite(handle: Int, index: Int, value: Int)
    case auxDelete(handle: Int)
}
