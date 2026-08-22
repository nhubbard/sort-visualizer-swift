import Testing
import ToneKitDSP

@testable import ToneKitAVFoundation

/// `ToneVoice`'s actual DSP behavior (frequency/gate handling, silence-until-opened, etc.) is
/// already covered by `ToneKitDSPTests`' `ToneRendererTests` — `ToneVoice` is a thin wiring layer
/// on top, so this test only checks that the wiring itself (Node conformance, attaching to an
/// engine) works.
@MainActor
@Suite
struct ToneVoiceTests {
  @Test
  func attachesToAnEngineLikeAnyOtherNode() {
    let engine = AudioEngine()
    let renderer = ToneRenderer(oscillator: OscillatorDSP(frequency: 440), envelope: EnvelopeDSP())
    let voice = ToneVoice(renderer: renderer)

    engine.output = voice

    #expect(engine.avEngine.attachedNodes.contains(voice.avAudioNode))
  }
}
