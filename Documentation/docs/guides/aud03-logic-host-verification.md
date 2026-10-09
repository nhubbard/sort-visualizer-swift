# AUD-03 Logic Pro host verification

On 2026-10-04, the signed Mac Catalyst app and its AUv3 extension were exercised in Logic
Pro using a copy of the existing Sort Symphony project. The copy and raw recordings are at
`/private/tmp/AUD03 Host Test 2026-10-04.logicx`. The original Logic project was not edited.

The Logic software-instrument track hosted Sort Symphony and sent its output to Bus 1. A
record-enabled stereo audio track took Bus 1 as input. Count-in and metronome were off. The
standalone app showed its Audio Unit Bridge as Connected and sound effects as on. Each pass
recorded a Quick Sort reset through the normal app run controls while Logic recorded the
audio track. The sort ran at the default one-second target; the longer recording duration
includes setup time and silence before and after the sort.

The first pass used the AU's default Gain 1. The second used Logic's hosted generic Controls
view to set the AU Gain parameter to 0. Logic displayed `0 Gain`; switching to the custom
Sort Symphony parameter view showed `Gain: 0.000` and a zero-position slider. This checks
that a host-originated parameter edit reaches both the audio unit and its custom view.

The raw host recordings are `Media/Audio Files/Sort Symphony Output Audio #01.aif` and
`#02.aif` inside the copied Logic project. Both are 48 kHz stereo, 24-bit AIFF. The
reproducible measurement command is:

```sh
python3 Tools/AUv3HostCanary/analyze_capture.py \
  '/private/tmp/AUD03 Host Test 2026-10-04.logicx/Media/Audio Files/Sort Symphony Output Audio #01.aif' \
  '/private/tmp/AUD03 Host Test 2026-10-04.logicx/Media/Audio Files/Sort Symphony Output Audio #02.aif'
```

`ffmpeg` decodes each file to float PCM. The check requires populated output for Gain 1 and
exact digital silence for Gain 0, independently of recording length. Results:

| Host Gain | Duration | Peak | Whole-file RMS | Nonzero samples |
| --- | ---: | ---: | ---: | ---: |
| 1 | 37.91 s | 0.941981792 | 0.045191078 | 179,709 |
| 0 | 38.88 s | 0 | 0 | 0 |

The Gain 1 recording's energy occurred during seconds 11–13 after recording started, when
the app sort ran. The Gain 0 recording was silent for every decoded sample. This is a
Logic-hosted, real-time capture: an offline bounce would not drive the bridge's live app
session. The existing extension component tests separately assert that parameter model
edits reach the AU parameter tree and host-originated changes reach the view model, including
after observer reconnection.
