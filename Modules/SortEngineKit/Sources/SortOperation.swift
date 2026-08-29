/// A single logical step an algorithm performs against a `RecordingEngine`. A `Tape` is nothing
/// more than an ordered array of these — replaying them one at a time is the entire mechanism
/// behind stepping, scrubbing, and speed control (see Documentation/docs/architecture/engine.md).
public enum SortOperation: Sendable, Codable, Equatable {
  case swap(Int, Int)
  case setValue(Int, Int)
  /// ArrayV-style: persists on `index` until `.unmark`/`.unmarkAll`/`.unmarkIndex` clears it.
  case mark(marker: Int, index: Int)
  case unmark(marker: Int)
  case unmarkAll
  /// O(1) removal of `marker` from one `index` — distinct from `.unmark`, which scans every
  /// index. What `RecordingEngine.compare`/`.swap` emit to retract the *previous* operation's
  /// highlight before applying the new one, so `Marker.primary`/`.secondary` only ever sit on
  /// the pair actively being touched right now, not every index a sort has ever compared.
  case unmarkIndex(marker: Int, index: Int)
  /// Counted, structurally inert — never changes `values`.
  case compare(Int, Int)
  /// Like `.compare`, but against a value an algorithm is holding onto rather than a second live
  /// array index (e.g. Cycle Sort's in-flight rotation value) — see
  /// `RecordingEngine.compareValue(_:against:by:)`. `(index, value)`.
  case compareValue(Int, Int)
  /// Permanent "done" marker at completion.
  case markSorted(Int)
  case auxCreate(handle: Int, length: Int)
  case auxWrite(handle: Int, index: Int, value: Int)
  case auxDelete(handle: Int)
  /// Like `.compareValue`, but for a comparison where *neither* side is a live array index (e.g.
  /// two held tree-node keys, two scratch-array entries) — see
  /// `RecordingEngine.compareValues(_:_:by:)`. `(a, b)` are the two held values themselves, not
  /// indices — there's nothing to highlight.
  case compareValues(Int, Int)
  /// A real re-read of a `writeAux`-shadowed buffer for a decision, distinct from the write
  /// itself — see `RecordingEngine.markAuxRead(_:at:)`. `(handle, index)`.
  case auxRead(handle: Int, index: Int)
  /// Counted, structurally inert — like `.compare`, never changes `values` on its own. Emitted
  /// once per `RecordingEngine.reversal(_:_:)` call, immediately before the individual `.swap`s
  /// that actually perform the flip, so a whole-range reverse is still visible swap-by-swap
  /// while scrubbing/stepping, but also counts as one `reversalCount`, matching ArrayV's
  /// `Writes.reversals` — a reversal is one *operation* built from many swaps, not its own kind
  /// of element move.
  case reversal

  /// Whether `SortFeature.SortSession.makeOnStepClosure` can ever play a note for this operation
  /// kind, matching that closure's switch exactly — `.compare`/`.swap`/`.setValue`, plus
  /// `.auxWrite` (writes to a shadow/auxiliary array, e.g. `LibrarySort`'s gapped `slots`
  /// structure or `MergeSort`'s staging buffer — real algorithmic work that used to be completely
  /// silent). `.auxWrite` is additionally *throttled* there (only every Nth occurrence actually
  /// plays, to avoid overwhelming algorithms that do tens of thousands of them), so this reflects
  /// "can this kind ever be audible," not "does this exact occurrence play."
  ///
  /// `Tools/SoundCoverageAudit/audit_sound_coverage.py`'s `AUDIBLE_TAGS` hand-maintains an
  /// identical mirror of this classification (Python can't import this enum) — keep the two in
  /// sync by hand if this ever changes.
  public var isAudible: Bool {
    switch self {
    case .compare, .compareValue, .swap, .setValue, .auxWrite: true
    case .mark, .unmark, .unmarkAll, .unmarkIndex, .markSorted, .auxCreate, .auxDelete, .reversal,
      .compareValues, .auxRead:
      // `.compareValues` has no live array position to sonify (unlike `.compareValue`, which
      // still has one real index). `.auxRead` risks the same "wall of noise" `.auxWrite` needed
      // throttling for (see `SortSession.makeOnStepClosure`) -- starting silent avoids needing
      // that same throttling from day one, since aux re-reads can vastly outnumber aux writes
      // (e.g. `GravitySort`'s O(n·k) reconstruction loop).
      false
    }
  }
}
