# Notice

`ToneKit`'s API — `Node`, `AudioEngine`, `Oscillator`, `Gated`, `AmplitudeEnvelope` — is modeled on
a small subset of three [AudioKit](https://github.com/AudioKit/AudioKit) organization projects:

- [AudioKit](https://github.com/AudioKit/AudioKit) (`Node`, `AudioEngine`)
- [AudioKitEX](https://github.com/AudioKit/AudioKitEX) (`Gated`)
- [SoundpipeAudioKit](https://github.com/AudioKit/SoundpipeAudioKit) (`Oscillator`,
  `AmplitudeEnvelope`, and the one-pole exponential envelope shape in `Soundpipe/modules/adsr.c`'s
  `sp_adsr_compute`)

None of the code here is copied from those projects — AudioKit's real `Oscillator`/
`AmplitudeEnvelope`/`Fader` are thin Swift parameter bindings around native Soundpipe C DSP kernels
reached through a custom Audio Unit host (`instantiate(instrument:/effect:)`), which pulls in the
`AudioKit`/`AudioKitEX`/`SoundpipeAudioKit`/`CSoundpipeAudioKit` package graph this module exists to
avoid. `ToneKit` reimplements just the shapes this project's `AudioEngineKit` module actually calls,
directly on `AVAudioEngine`/`AVAudioSourceNode`, with no `Fader`, waveform table, MIDI, automation,
or stereo support (all unused here) and no external package dependency at all.

Reused under the MIT License from both projects:

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
