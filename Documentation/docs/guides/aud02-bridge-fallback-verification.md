# AUD-02 bridge disconnect and local fallback verification

On 2026-10-04, Logic Pro hosted the signed Sort Symphony AUv3 from the saved test copy at
`/private/tmp/AUD03 Host Test 2026-10-04.logicx`. The standalone Catalyst app showed
`Audio Unit Bridge: On`, `Status: Connected`, and `Sound Effects: On`. Logic recorded a
Quick Sort through the bridge during the [AUD-03 host canary](aud03-logic-host-verification.md).

Closing only the Logic project window did not unload its AU client: the app still displayed
`Connected`. Quitting Logic after saving the test copy did unload the client, and the app
displayed `Waiting for Connection` while its bridge toggle and sound effects stayed on.
Reset and Reshuffle then started and completed another Quick Sort in the standalone app.
This exercised the app's live host-disconnect state transition and its subsequent sort path.

The Catalyst `AudioEngineKit` test
`NoOpAudioServiceTests.bridgeDisconnectRestoresRenderedLocalAudio` checks the audible
fallback at the PCM boundary. It uses the production `LocalToneEventSink`, `ToneMapper`, and
`ToneRenderer` with the same `AudioService.play` routing method as the app. While a bridge
client is connected, a sort event is broadcast and local rendering has zero peak. After
the bridge disconnect callback, the next sort event is not broadcast and the local
renderer produces a peak above 0.01. A fake hardware engine makes the test independent of
the Mac's selected speaker; the audio pipeline through the rendered stereo samples is real.
The pre-existing routing test separately checks bridge connection state, event counts,
live note range, stop, and listener failure.

`xcodebuild test -workspace 'Sort Symphony.xcworkspace' -scheme AudioEngineKit
-destination 'platform=macOS,variant=Mac Catalyst'` passed all 10 tests with no skips or
failures in `/private/tmp/aud02-fallback-2.xcresult`. The named fallback test passed. The
test does not measure a physical speaker or capture system output; its sound assertion is
at the local renderer's PCM output, immediately before the hardware adapter.
