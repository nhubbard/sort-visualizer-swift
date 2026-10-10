# Contextual onboarding with TipKit

Implemented 2026-10-08. Performance profiling was deferred at the owner's direction; this is the next completed item from [NEXT_STEPS.md](../../../NEXT_STEPS.md).

| Context | Tip | Appears when | Dismissed by |
| --- | --- | --- | --- |
| Catalog | Find an algorithm | The unfiltered catalog is open before an algorithm is selected | Choosing a category or algorithm, or entering a search |
| Sort playback | Explore one step at a time | A manual recording is ready and playback has not been used | Play, Pause, or Step Forward |
| Sort presentation | Change the view | Playback has been used and presentation has not been adjusted | Opening Array Size or Visualizer |
| Sort navigation | Revisit any operation | Presentation has been adjusted and the recording has not been sought | Dragging Playback Position or using either jump button |
| Reference code | Explore the implementation | Code examples have loaded and the user has not explored one | Changing language, toggling the full listing, or copying code |
| Recorded runs | Compare your recorded runs | At least two recorded array sizes produce a chart | Opening the expanded chart |
| Settings | Set defaults for future sorts | Settings is open and the user has not changed a default | Changing a playback, visualizer, shuffle, size, sound, recording-limit, or code-theme default |

The catalog tip obeys the app's daily TipKit display frequency. Tips in a reached workflow ignore that interval so an earlier catalog tip does not prevent contextual help on the sort or Settings screen. Each tip is capped at two displays and is invalidated after its associated action. Automated runs do not show the sort tips. The chart tip is absent from empty, sparse, and failed chart states. The permanent **How to Use** sheet remains available from a sort and now covers catalog browsing, playback, seeking, presentation, recorded charts, code, and tape saving.

## Verification

- Generated the Tuist workspace and built the Catalyst app.
- The focused `NavigationContentUITests` class passed on iPad Air 13-inch (M4), iPadOS 27.0, with code coverage collection disabled. It covers catalog, playback/presentation/seeking, Settings, code, recorded chart, and the existing empty-search journey.
- A separate iPad run passed the playback sequence again with an app relaunch, confirming completed tips remain dismissed.
- A final Catalyst build passed after the Settings dismissal update. Two Catalyst UI-test attempts timed out while Xcode enabled automation mode, before any test method began. Catalyst UI behavior is therefore not marked as manually verified.
- The first iPad suite with coverage collection enabled stalled in Xcode's test-session log cleanup and produced no usable result bundle. It is not counted as a pass or an app failure.
