# Notice

`ToneKitAVFoundation`'s `Node`/`AudioEngine` API is modeled on a subset of
[AudioKit](https://github.com/AudioKit/AudioKit)'s own `Node`/`AudioEngine`.

This module is a Phase 1 split of what was previously `ToneKit` (see that module's own history) into
an `AVFoundation`-coupled adapter (this module) and a host-independent DSP core (`ToneKitDSP`) — see
Documentation/docs/architecture/audio.md for why. `ToneVoice`, which wires `ToneKitDSP`'s `ToneRenderer` into an
`AVAudioSourceNode`, is new to this split and not modeled on any AudioKit type. (An earlier version
of this module also carried a `Gated` protocol modeled on AudioKitEX, for `ToneVoice`'s own
`openGate()`/`closeGate()` API — removed in Phase 2 once `SortAudioCore.LocalToneEventSink` took over
driving the renderer directly, so nothing implements `Gated` anymore.) None of the code here is
copied from AudioKit — its real equivalent pulls in the full `AudioKit`/`AudioKitEX`/
`SoundpipeAudioKit`/`CSoundpipeAudioKit` package graph this module exists to avoid, reimplementing
just the one fixed `AVAudioEngine` chain this project's `AudioEngineKit` module actually needs.

Reused under the MIT License:

```
MIT License

Copyright (c) 2016 Aurelius Prochazka (AudioKit)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
