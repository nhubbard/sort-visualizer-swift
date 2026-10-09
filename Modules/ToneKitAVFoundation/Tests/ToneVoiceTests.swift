import AVFoundation
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

  @Test
  func sourceNodeRendersSilenceUntilItsSharedRendererOpensTheGate() throws {
    let engine = AudioEngine()
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.0001))
    let voice = ToneVoice(renderer: renderer, maxFrameCount: 512)
    engine.output = voice
    try engine.avEngine.enableManualRenderingMode(
      .offline, format: voice.outputFormat, maximumFrameCount: 512)
    try engine.start()
    defer { engine.stop() }

    let buffer = AVAudioPCMBuffer(pcmFormat: engine.avEngine.manualRenderingFormat, frameCapacity: 512)!
    #expect(try engine.avEngine.renderOffline(512, to: buffer) == .success)
    let left = buffer.floatChannelData![0]
    let right = buffer.floatChannelData![1]
    #expect((0..<512).allSatisfy { left[$0] == 0 })
    #expect((0..<512).allSatisfy { right[$0] == 0 })

    renderer.enqueue(.openGate)
    #expect(try engine.avEngine.renderOffline(512, to: buffer) == .success)
    #expect((0..<512).contains { abs(left[$0]) > 0.0001 })
    #expect((0..<512).contains { abs(right[$0]) > 0.0001 })
  }
}
