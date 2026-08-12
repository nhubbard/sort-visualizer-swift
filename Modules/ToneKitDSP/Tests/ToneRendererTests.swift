import Testing

@testable import ToneKitDSP

@Suite
struct ToneRendererTests {
  @Test
  func renderIsSilentUntilGateOpens() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1), envelope: EnvelopeDSP())
    renderer.prepare(maxFrameCount: 8)
    var buffer = [Float](repeating: -1, count: 8)
    buffer.withUnsafeMutableBufferPointer { renderer.render(into: $0, sampleRate: 44100) }
    #expect(buffer.allSatisfy { $0 == 0 }, "gate never opened, so gain should stay 0 throughout")
  }

  @Test
  func openGateCommandRampsGainUpFromZero() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.001))
    renderer.prepare(maxFrameCount: 512)
    renderer.enqueue(.openGate)
    var buffer = [Float](repeating: -1, count: 512)
    buffer.withUnsafeMutableBufferPointer { renderer.render(into: $0, sampleRate: 44100) }
    #expect(!buffer.allSatisfy { $0 == 0 }, "an open gate should let some nonzero samples through")
  }

  @Test
  func closeGateCommandEventuallySilencesOutputAgain() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.0001, releaseDuration: 0.0001))
    renderer.prepare(maxFrameCount: 4096)
    renderer.enqueue(.openGate)
    var opened = [Float](repeating: -1, count: 4096)
    opened.withUnsafeMutableBufferPointer { renderer.render(into: $0, sampleRate: 44100) }
    #expect(!opened.allSatisfy { $0 == 0 })

    renderer.enqueue(.closeGate)
    // Several buffers of release time at a 0.0001s time constant and 44.1kHz settle to silence
    // well within this many samples.
    var closed = [Float](repeating: -1, count: 4096)
    for _ in 0..<10 {
      closed.withUnsafeMutableBufferPointer { renderer.render(into: $0, sampleRate: 44100) }
    }
    #expect(closed.allSatisfy { abs($0) < 0.0001 })
  }

  @Test
  func setFrequencyCommandChangesEffectiveFrequency() {
    // A very fast attack so gain saturates near 1 by the second sample, so the envelope's ramp
    // doesn't mask the oscillator-frequency divergence this test is actually checking for.
    let unchanged = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    let changed = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    unchanged.prepare(maxFrameCount: 4)
    changed.prepare(maxFrameCount: 4)
    unchanged.enqueue(.openGate)
    changed.enqueue(.openGate)
    changed.enqueue(.setFrequency(220))

    var unchangedBuffer = [Float](repeating: -1, count: 4)
    var changedBuffer = [Float](repeating: -1, count: 4)
    unchangedBuffer.withUnsafeMutableBufferPointer { unchanged.render(into: $0, sampleRate: 44100) }
    changedBuffer.withUnsafeMutableBufferPointer { changed.render(into: $0, sampleRate: 44100) }

    // Both start at phase 0 (identical first sample), but a genuinely different frequency must
    // diverge by the second sample — mirrors OscillatorDSPTests' detuning test.
    #expect(abs(unchangedBuffer[0] - changedBuffer[0]) < 0.0001)
    #expect(abs(unchangedBuffer[1] - changedBuffer[1]) > 0.0001)
  }
}
