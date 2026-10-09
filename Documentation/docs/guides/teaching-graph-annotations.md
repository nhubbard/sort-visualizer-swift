# Teaching graph annotations

**Status:** All 196 built-in sorts now author decision or placement explanations at their recording
sites. Shared templates supply context to variants that delegate their sorting logic. The tape
carries a versioned, optional annotation sidecar through export, import, and fast-playback
compaction. The Teaching Graph renders that sidecar for every annotated algorithm and retains
operation-derived explanations for older Quick Sort and Merge Sort tapes. A fixed flowchart remains
future work.

## Goal

A tape operation tells us **what** happened: two positions were compared, a value moved, or a
buffer was written. It cannot reliably tell us **why**. In Quick Sort, a comparison may decide
which side of a pivot an item belongs on. In Merge Sort, a comparison chooses the next output
item. An annotation should capture that decision and its result while the algorithm still knows
the relevant pivot, run boundaries, branch, and destination.

The same annotation can supply a caption beside the existing graph,
and the active stage or branch in a future fixed flowchart. The graph remains useful without
annotations: older imported tapes keep their current behavior.

## Shape of an annotation

Keep annotations in an optional, ordered side stream associated with a tape. Do not add an
annotation case to `SortOperation`: annotations do not sort values, change operation counts,
produce sound, or advance playback on their own. Each record has:

| Field | Meaning |
| --- | --- |
| `operationIndex` | Zero-based index of the meaningful tape operation whose result this explains. The explanation becomes current after that operation is applied, at `stepIndex == operationIndex + 1`. |
| `stageID` | Stable identifier for a broad algorithm stage, such as `partition.scanRight` or `merge.chooseNext`. A static flowchart may highlight this stage. |
| `decisionID` | Stable identifier for the question within that stage, if there is one. |
| `outcome` | A stable result identifier such as `left`, `right`, `advance`, or `stop`, interpreted by that algorithm's teaching definition. |
| `roles` | Named, typed references to live array positions, auxiliary-buffer positions, values, or ranges. These can drive graph focus and caption parameters. |
| `explanationKey` | A stable explanation identifier for future localized templates. |
| `explanation` | Optional readable text for the exact recorded decision. Older archives omit it. |

The identifiers belong to a versioned **teaching definition** for an algorithm or a closely
related variant. Today the graph uses the embedded explanation. The stable identifiers can later
support localized text, stage labels, and optional flowchart branches. Sharing identifiers across
a family is appropriate only when its decisions actually have the same meaning.

The implementation keeps the schema small. Its shape is:

```swift
struct TeachingAnnotation: Sendable, Codable {
  let operationIndex: Int
  let definitionVersion: Int
  let stageID: String
  let decisionID: String?
  let outcome: String
  let roles: [String: TeachingReference]
  let explanationKey: String
  let explanation: String?
}

enum TeachingReference: Sendable, Codable {
  case arrayIndex(Int)
  case auxiliaryIndex(handle: Int, index: Int)
  case value(Int)
  case range(Range<Int>)
}
```

The built-in comparison helpers attach the result and its explanation immediately after the real
comparison. Stored IDs remain stable so archived annotations can be decoded without loading the
original algorithm implementation. Readable text travels with the tape until localized templates
are available.

## Recording at the decision site

`RecordingEngine` is the only interface an algorithm uses to record work. It now has a narrow
method that attaches an annotation to the **last retained meaningful operation**. The algorithm
calls it immediately after the comparison, read, swap, or write whose result it explains. The
method must reject an absent or cosmetic-marker anchor; it must not append a `SortOperation`.
Existing `compare`, `compareValue`, and `compareValues` calls still perform the real comparisons,
and `readValue`/`readValues` still record live reads. An annotation is never a substitute for
those calls.

`teachingReversal` records the same reversal and internal swaps as `reversal`, while attaching a
reason to each retained swap. Use it when a long reversed run would otherwise leave the Teaching
Graph silent through much of the replay.

For example, a Quick Sort partition can record the comparison result and then annotate the
branch using its known pivot and scan position:

```swift
let belongsOnLeft = engine.compare(pivot, scan)
engine.annotateLastOperation(
  stageID: "quick.partition.scanLeft",
  decisionID: "quick.pivotSide",
  outcome: !belongsOnLeft ? "oppositeSide" : (scan < boundary ? "advance" : "boundary"),
  roles: ["pivot": .arrayIndex(pivot), "candidate": .arrayIndex(scan)],
  explanationKey: "quick.pivotSide")
if belongsOnLeft && scan < boundary { scan += 1 }
```

The exact comparison direction and wording must match the particular Quick Sort variant. For
Merge Sort, the annotation can say which run supplied the next value and why the left item wins
on equality. A separate annotation on the buffer write can identify the destination. Tests
should prove the annotated version records the same operations and sort result as before.

Annotations mark *meaningful transitions*, not cosmetic markers. The recorder retains at most
2,048 annotations and increases its sampling stride for long recordings. This bounds sidecar
storage while keeping explanations distributed through a run.

## Replay, seeking, and fast playback

The recorder first emits indices relative to the sort phase. `TapeFactory` already concatenates
shuffle and sort operations; it adds `sortStartIndex` to each sort annotation's index when forming
the combined tape. Every annotation must then satisfy
`sortStartIndex <= operationIndex < operations.count` and point to the expected operation kind.

`ReplayEngine.stepIndex` counts applied operations. At any position, the current graph event is
the last event whose `step <= stepIndex`. The existing trace binary search keeps seeking
independent of re-running algorithm code. Multiple annotations on one operation retain recording
order in the tape. The visible graph keeps a short recent window while text and event navigation cover the complete
annotation stream.

`Tape.compactedForFastPlayback()` drops cosmetic markers. The annotation API anchors only to
operations that compaction keeps. During compaction, build an old-to-new operation-index mapping
and remap each annotation to its kept operation. Also remap `sortStartIndex`, as the current tape
code does. Test that event order, outcomes, explanations, and navigation are identical before and
after compaction. Capped recordings are already skipped; they must not yield a partial teaching
stream that looks complete.

## Reading pace during automatic playback

Annotations are teaching content, not playback telemetry. During automatic playback, keep the
displayed annotation, its graph focus, and any flowchart highlight **frozen** whenever the actual
replay pace exceeds a very slow reading threshold. Start with **one significant operation per
second** as the threshold and tune it through hands-on reading tests. The default 30 operations
per second should therefore never cycle explanations past the reader. The main sort visualization,
audio, tape position, and recording continue normally.

The teaching view owns a `displayedStep` separate from `ReplayEngine.stepIndex`. On entering fast
playback it retains the last explanation the user could read; if none has appeared, it shows
“Pause or slow playback to read decisions.” Mark a retained explanation as **Pinned while playback
is fast** so it is not mistaken for the operation currently on screen. Do not queue a backlog of
captions to play later. The full annotation stream remains available through Previous and Next
Graph Event.

When playback pauses, completes, or drops to the reading threshold, set `displayedStep` to the
current replay position and show the matching annotation. A deliberate step or seek updates the
teaching view immediately even if the speed setting remains high. If automatic slow playback
would still change annotations too quickly, hold each explanation for at least three seconds and
skip intermediate automatic updates; manual navigation continues to reach every event. The pilot
does not post automatic VoiceOver announcements for replay events. A hands-on assistive-technology
pass should determine whether deliberate navigation or pin-state changes need a single announcement.

The threshold uses the **actual** pacing rate. In flat-rate mode this accounts for an automatic
speed limit; in fixed-duration mode it follows the changing rate applied by the replay loop.
The teaching view samples `ReplayEngine.currentPacingRate` every 100 milliseconds in its own task,
without adding a new per-tick observable property. A hysteresis band may help if hands-on tests
find rapid switching near the threshold. The threshold and dwell time are presentation constants,
not tape data; they do not change replay or annotation indices.

## Compatibility and presentation

The optional archive trailer has an `ANNO` marker and schema version. Archives without the trailer
still decode; a future unknown trailer version is skipped after its bounded length is read.
Older Quick Sort and Merge Sort annotations without embedded text use their key-based explanation
resolver. Other unknown keys use a plain stage-and-outcome caption and leave replay intact. The
current format tests cover round trips with and without annotations.
Imported old tapes continue using the existing Quick Sort and Merge Sort trace reconstruction.

The UI should show one concise decision explanation and, when useful, its consequence. VoiceOver
reads the same text. The current dynamic graph may use `roles` to focus the corresponding nodes
and edges. A fixed flowchart can use `stageID`, `decisionID`, and `outcome` to highlight a node
and branch without replacing the replay-linked graph. Both views consume the same annotation
stream; no algorithm should have to maintain separate teaching data for each view.

For an imported tape without authored annotations, do not invent a cause from a generic
`.compare`. Show the ordinary visualization and reference explanation; the Quick Sort and Merge
Sort trace adapters remain for older imported tapes.

## Verification

The catalog coverage test records all 196 built-in sorts on reversed and duplicate-heavy inputs
at representative reachable sizes. It checks sorting, valid annotation anchors, readable
explanations, and event distribution across all four replay quartiles. A second pass exercises
practical sorts at their reachable size up to the app's 256-item default; a dedicated Bingo Sort
case checks a 128-item replay. Engine tests cover optional archive decoding, index shifting,
compaction, recording caps, and the annotation storage bound. Teaching Graph tests cover replay
positions, navigation, held-value nodes, and fast-playback pinning. Run the engine access audit after editing algorithms
to ensure live reads and comparisons still enter the tape.
