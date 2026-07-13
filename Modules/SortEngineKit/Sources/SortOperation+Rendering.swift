/// Support for renderers that repaint incrementally (only the array positions an operation
/// actually touched) instead of redrawing the whole frame on every applied operation — see
/// `ReplayEngine.onOperationApplied`. Deliberately lives alongside `SortOperation` itself rather
/// than in a UI-facing module, since "which positions did this operation touch" is a property of
/// the operation, not of any particular renderer.
extension SortOperation {
    /// The bar positions this operation visibly affects, if any. `nil` (rather than an empty
    /// array) specifically means "this operation can affect positions beyond what its own
    /// payload names" — `.unmark`/`.unmarkAll` clear a marker from every index that currently
    /// carries it, and a per-operation touched-index list has no way to know which those are
    /// without scanning the whole frame, so a caller doing incremental repainting must fall back
    /// to a full repaint for exactly those two cases. An empty array (`.auxCreate`/`.auxWrite`/
    /// `.auxDelete`/`.reversal`) means the opposite: this operation is known to touch no bar
    /// position at all (aux-array operations only affect `auxArrays`, which the bar-graph-specific
    /// incremental renderers this supports don't draw; `.reversal` is a structurally-inert marker
    /// whose constituent element moves arrive as their own separate `.swap` operations).
    public var touchedIndices: [Int]? {
        switch self {
        case let .swap(i, j): return [i, j]
        case let .setValue(i, _): return [i]
        case let .mark(_, index): return [index]
        case let .unmarkIndex(_, index): return [index]
        case let .compare(i, j): return [i, j]
        case let .markSorted(i): return [i]
        case .unmark, .unmarkAll: return nil
        case .auxCreate, .auxWrite, .auxDelete, .reversal: return []
        }
    }

    /// Whether this operation represents real algorithmic work for `ReplayEngine.play()`'s
    /// `speed` (ops/sec) pacing budget, as opposed to bookkeeping the recorder emits alongside it
    /// (`RecordingEngine.markPrimarySecondary`'s auto mark/unmark pair around every `.compare`/
    /// `.swap`, `.unmarkAll`, and aux-buffer lifecycle events). `false` here does NOT mean "not
    /// applied" or "not rendered" — every operation in the tape still gets applied to `state` and
    /// still reaches `onStep`/`onOperationApplied` exactly as before; it only means this operation
    /// doesn't consume a unit of the pacing budget on its own; see `play()`'s tick loop.
    var isSignificantForPacing: Bool {
        switch self {
        case .swap, .setValue, .auxWrite, .reversal, .compare, .markSorted: return true
        case .mark, .unmark, .unmarkAll, .unmarkIndex, .auxCreate, .auxDelete: return false
        }
    }
}
