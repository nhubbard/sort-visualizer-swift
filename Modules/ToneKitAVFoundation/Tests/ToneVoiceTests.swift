import Testing
import ToneKitDSP

@testable import ToneKitAVFoundation

/// `ToneVoice`'s actual DSP behavior (frequency/gate handling, silence-until-opened, etc.) is
/// already covered by `ToneKitDSPTests`' `ToneRendererTests` — `ToneVoice` is a thin wiring layer
/// on top, so these tests only check that the wiring itself (Node conformance, attaching to an
/// engine, the control-side API not crashing) works.
@MainActor
@Suite
struct ToneVoiceTests {
  @Test
  func attachesToAnEngineLikeAnyOtherNode() {
    let engine = AudioEngine()
    let voice = ToneVoice(oscillator: OscillatorDSP(frequency: 440), envelope: EnvelopeDSP())

    engine.output = voice

    #expect(engine.avEngine.attachedNodes.contains(voice.avAudioNode))
  }

  @Test
  func frequencyOpenGateAndCloseGateNeverCrash() {
    let voice = ToneVoice(oscillator: OscillatorDSP(frequency: 440), envelope: EnvelopeDSP())
    voice.frequency = 880
    voice.openGate()
    voice.closeGate()
  }
}
