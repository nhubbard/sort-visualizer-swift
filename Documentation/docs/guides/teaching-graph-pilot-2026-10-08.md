# Teaching graph pilot

The sort detail view offers a Teaching Graph for the built-in Quick Sort and Merge Sort. Open the disclosure below the visualization. Its Previous Graph Event and Next Graph Event controls seek the same replay used by the visualizer and playback slider. The current event is also written as text for VoiceOver and other nonvisual use.

## Meaning

- A numbered node is an array position. `B` followed by a number is a temporary merge buffer position.
- A dashed connection records a comparison. A solid connection records a swap, pivot placement, buffer write, or write back to the array. The latest connection is emphasized.
- Quick Sort omits each partition's self-comparison, then shows pivot comparisons, in-partition swaps, and pivot placement.
- Merge Sort shows comparisons between runs, the source position of each value moved into the temporary buffer, and each write back to the main array.

The graph displays at most ten recent events and twelve positions. Its text and navigation cover the complete run even when older edges leave the drawing. A snapshot is derived from the played tape at the current `ReplayEngine.stepIndex`; seeking to any operation reconstructs the same event and recent connections. The graph uses the replay tape after fast-playback compaction, so no separate position remapping or tape archive change is required. Imported tapes with either supported algorithm ID use the same path.

## Pilot boundary

The graph is available during manual playback. Automated showcase and size-sweep runs retain their compact detail placeholder. Other algorithms do not yet have semantic graph models. Side-by-side algorithm comparison remains a separate design decision; this pilot establishes the meaning and replay behavior of one graph first.

[Teaching graph annotations](teaching-graph-annotations.md) describes how the two pilot algorithms
record the reason for a decision alongside the replay tape. The same annotation fields can later
drive a fixed flowchart without guessing intent from a generic operation.

The first annotation implementation now covers branch decisions in Quick Sort and Merge Sort.
During playback faster than one significant operation per second, the teaching explanation and
graph focus stay pinned while the main sort continues. Pausing, stepping, seeking, or returning
to the reading pace brings the graph to the corresponding event. Older tapes retain the original
operation-derived explanations.

## Verification

`TeachingGraphTraceTests` covers complete Quick Sort and Merge Sort tapes, sorted/reversed/duplicate-heavy inputs, every replay position, forward and backward event navigation, the shuffle boundary, visible-density caps, unsupported algorithms, and fast-playback compaction. `TeachingGraphUITests` covers opening each pilot graph, event navigation, buffer explanation, and the playback status when reviewing an earlier operation. Catalyst was also inspected manually for distinct accessibility controls and synchronized replay positions.
