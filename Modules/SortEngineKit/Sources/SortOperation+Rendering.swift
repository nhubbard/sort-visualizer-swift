/// Support for renderers that repaint incrementally (only the array positions an operation
/// actually touched) instead of redrawing the whole frame on every applied operation — see
/// `ReplayEngine.onOperationApplied`. Deliberately lives alongside `SortOperation` itself rather
/// than in a UI-facing module, since "which positions did this operation touch" is a property of
/// the operation, not of any particular renderer.
extension SortOperation {
  /// The bar positions this operation visibly affects, if any. `nil` (not an empty array) means
  /// "this operation can affect positions beyond what its own payload names" — `.unmark`/
  /// `.unmarkAll` clear a marker from every index currently carrying it, which a per-operation
  /// touched-index list can't know without scanning the whole frame, so callers doing incremental
  /// repainting must fall back to a full repaint for those two cases. An empty array
  /// (`.auxCreate`/`.auxWrite`/`.auxDelete`/`.reversal`) means the operation touches no bar
  /// position at all — aux-array ops only affect `auxArrays`; `.reversal`'s element moves arrive
  /// as their own separate `.swap` operations.
  public var touchedIndices: [Int]? {
    switch self {
    case .swap(let i, let j): return [i, j]
    case .setValue(let i, _): return [i]
    case .mark(_, let index): return [index]
    case .unmarkIndex(_, let index): return [index]
    case .compare(let i, let j): return [i, j]
    case .markSorted(let i): return [i]
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
