# Notice

`ToneKitDSP`'s API — `OscillatorDSP`, `EnvelopeDSP` — is modeled on a subset of
[SoundpipeAudioKit](https://github.com/AudioKit/SoundpipeAudioKit) (`Oscillator`,
`AmplitudeEnvelope`, and the one-pole exponential envelope shape in `Soundpipe/modules/adsr.c`'s
`sp_adsr_compute`).

This module is a Phase 1 split of what was previously `ToneKit` (see that module's own history) into
a host-independent DSP core (this module) and an `AVFoundation`-coupled adapter
(`ToneKitAVFoundation`) — see Documentation/docs/architecture/audio.md for why. None of the code here is copied from
SoundpipeAudioKit — its real `Oscillator`/`AmplitudeEnvelope` are thin Swift parameter bindings
around native Soundpipe C DSP kernels reached through a custom Audio Unit host, which pulls in the
`AudioKit`/`AudioKitEX`/`SoundpipeAudioKit`/`CSoundpipeAudioKit` package graph this module exists to
avoid. `ToneKitDSP` reimplements just the oscillator/envelope math this project's `ToneKitAVFoundation`
and (later) AU/VST3 adapters actually need, with no waveform table, MIDI, automation, or stereo
support (all unused here) and no external package dependency at all — not even `AVFoundation`.

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
