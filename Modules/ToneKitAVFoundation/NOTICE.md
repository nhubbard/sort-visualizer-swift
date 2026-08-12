# Notice

`ToneKitAVFoundation`'s API — `Node`, `AudioEngine`, `Gated` — is modeled on a subset of two
[AudioKit](https://github.com/AudioKit/AudioKit) organization projects:

- [AudioKit](https://github.com/AudioKit/AudioKit) (`Node`, `AudioEngine`)
- [AudioKitEX](https://github.com/AudioKit/AudioKitEX) (`Gated`)

This module is a Phase 1 split of what was previously `ToneKit` (see that module's own history) into
an `AVFoundation`-coupled adapter (this module) and a host-independent DSP core (`ToneKitDSP`) — see
`AUDIO_UNIT_PLAN.md` §3 for why. `ToneVoice`, which wires `ToneKitDSP`'s `ToneRenderer` into an
`AVAudioSourceNode`, is new to this split and not modeled on any AudioKit type. None of the code here
is copied from AudioKit/AudioKitEX — their real equivalents pull in the full
`AudioKit`/`AudioKitEX`/`SoundpipeAudioKit`/`CSoundpipeAudioKit` package graph this module exists to
avoid, reimplementing just the one fixed `AVAudioEngine` chain this project's `AudioEngineKit` module
actually needs.

Reused under the MIT License:

```
MIT License

Copyright (c) 2016 Aurelius Prochazka (AudioKit)
Copyright (c) 2021 AudioKit (AudioKitEX, SoundpipeAudioKit)

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
