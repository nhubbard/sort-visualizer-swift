# Live video recording

Sort Symphony records the visible run at its actual playback pace. Open a sort, choose **Record Video**, play or scrub the run, then choose **Stop Recording**. The resulting MP4 can be previewed in the app or shared through the system share sheet, including Save to Files where available. Recording a video does not change or replace the sort's tape.

On Mac Catalyst 18.2 and later, ScreenCaptureKit starts directly when Sort Symphony has one visible normal window. If there are multiple windows, or the app cannot identify its window, the system's single-window picker asks which window to record. ScreenCaptureKit captures the window and app audio, and finalizes the file before the preview and share controls appear. If ScreenCaptureKit is unavailable, **Record App Instead** starts an app-only ReplayKit capture. On iPadOS, and on Catalyst 18.0–18.1, ReplayKit captures the app screen and app audio. The microphone stays off. ReplayKit's recording API is available in the app's iPadOS 18 deployment range; the ScreenCaptureKit module is not available in the current iOS Simulator SDK used by this project.

Cancel leaves the run untouched. A denied permission, unavailable recorder, interruption, start timeout, or empty output displays an error and allows another attempt. Videos are created in the app's temporary directory; use **Share Video** to keep a copy outside the app. A recording is live capture, so the video's length follows actual playback rather than a fixed frame rate or a deterministic export clock.

## Verification

- The SortFeature test target compiles on Catalyst with tests for success, cancellation, interruption, picker fallback, retry after permission failure, and invalid output. The Xcode test runner timed out in this host session, so those tests did not report a pass. A direct executable smoke check passed for successful output and picker replacement.
- SortFeature compiles for iOS Simulator and Catalyst with their respective capture backends.
- The Catalyst UI exposes the recording action, selection state, and app-only fallback. In this host session, ScreenCaptureKit logged a picker start but did not display its picker; ReplayKit accepted a start request but did not call back promptly. The UI can cancel either pending start, and ReplayKit now times out with a retry message. End-to-end capture, system picker selection, file finalization, and sharing need a manual run on a signed device or host with working capture services.
