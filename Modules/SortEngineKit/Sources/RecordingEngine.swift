/// A plain, synchronous, `mutating`-method struct — no actor, no `async`, no `@MainActor`. This is
/// the *only* interface an algorithm ever touches. `compare`/`swap` auto-apply
/// `Marker.primary`/`.secondary` (matching ArrayV's `Reads.compareIndices`/`Writes.swap`
/// convention of always marking what they touch); everything past that — `pivot`, `bucket(n)`,
/// custom markers — is the algorithm's own choice, held across as many operations as it likes.
///
/// A synchronous function cannot be cancelled mid-loop-body anyway, so there is no
/// `enforceRunning()`-style guard anywhere here — cancellation is a `ReplayEngine` concern.
public struct RecordingEngine: Sendable {
    public private(set) var values: [Int]
    private var tape: [SortOperation] = []
    private var compareCount = 0
    private var swapCount = 0
    private var auxWriteCount = 0
    private var nextAuxHandle = 0

    public init(values: [Int]) {
        self.values = values
    }

    public var count: Int { values.count }

    @discardableResult
    public mutating func compare(_ i: Int, _ j: Int, by cmp: (Int, Int) -> Bool = (>=)) -> Bool {
        tape.append(.mark(marker: Marker.primary, index: i))
        tape.append(.mark(marker: Marker.secondary, index: j))
        tape.append(.compare(i, j))
        compareCount += 1
        return cmp(values[i], values[j])
    }

    public mutating func swap(_ i: Int, _ j: Int) {
        tape.append(.mark(marker: Marker.primary, index: i))
        tape.append(.mark(marker: Marker.secondary, index: j))
        tape.append(.swap(i, j))
        values.swapAt(i, j)
        swapCount += 1
    }

    public mutating func setValue(_ i: Int, _ value: Int) {
        tape.append(.mark(marker: Marker.write, index: i))
        tape.append(.setValue(i, value))
        values[i] = value
    }

    public mutating func mark(_ marker: Int, at index: Int) {
        tape.append(.mark(marker: marker, index: index))
    }

    public mutating func unmark(_ marker: Int) {
        tape.append(.unmark(marker: marker))
    }

    public mutating func unmarkAll() {
        tape.append(.unmarkAll)
    }

    /// Scratch buffers for algorithms that need one — LSD Radix's per-digit registers, merge
    /// sort's temp array, bucket sort's buckets. Mirrors ArrayV's `Writes.createExternalArray`.
    public mutating func createAuxArray(length: Int) -> AuxHandle {
        defer { nextAuxHandle += 1 }
        tape.append(.auxCreate(handle: nextAuxHandle, length: length))
        return AuxHandle(rawValue: nextAuxHandle)
    }

    public mutating func writeAux(_ handle: AuxHandle, at index: Int, value: Int) {
        tape.append(.auxWrite(handle: handle.rawValue, index: index, value: value))
        auxWriteCount += 1
    }

    public mutating func deleteAuxArray(_ handle: AuxHandle) {
        tape.append(.auxDelete(handle: handle.rawValue))
    }

    public mutating func markSorted(_ i: Int) {
        tape.append(.markSorted(i))
    }

    public func finish() -> (tape: [SortOperation], compareCount: Int, swapCount: Int, auxWriteCount: Int) {
        (tape, compareCount, swapCount, auxWriteCount)
    }
}
