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

  @Test
  func setAmplitudeCommandScalesPeakOutput() {
    let full = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    let halved = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    full.prepare(maxFrameCount: 512)
    halved.prepare(maxFrameCount: 512)
    full.enqueue(.openGate)
    halved.enqueue(.openGate)
    halved.enqueue(.setAmplitude(0.5))

    var fullBuffer = [Float](repeating: 0, count: 512)
    var halvedBuffer = [Float](repeating: 0, count: 512)
    fullBuffer.withUnsafeMutableBufferPointer { full.render(into: $0, sampleRate: 44100) }
    halvedBuffer.withUnsafeMutableBufferPointer { halved.render(into: $0, sampleRate: 44100) }

    let fullPeak = fullBuffer.map { abs($0) }.max() ?? 0
    let halvedPeak = halvedBuffer.map { abs($0) }.max() ?? 0
    #expect(halvedPeak < fullPeak * 0.6, "halved amplitude should roughly halve peak output")
  }

  @Test
  func setDetuningOffsetCommandChangesEffectiveFrequency() {
    let unchanged = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    let detuned = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    unchanged.prepare(maxFrameCount: 4)
    detuned.prepare(maxFrameCount: 4)
    unchanged.enqueue(.openGate)
    detuned.enqueue(.openGate)
    detuned.enqueue(.setDetuningOffset(50))

    var unchangedBuffer = [Float](repeating: -1, count: 4)
    var detunedBuffer = [Float](repeating: -1, count: 4)
    unchangedBuffer.withUnsafeMutableBufferPointer { unchanged.render(into: $0, sampleRate: 44100) }
    detunedBuffer.withUnsafeMutableBufferPointer { detuned.render(into: $0, sampleRate: 44100) }

    #expect(abs(unchangedBuffer[0] - detunedBuffer[0]) < 0.0001)
    #expect(abs(unchangedBuffer[1] - detunedBuffer[1]) > 0.0001)
  }

  @Test
  func setSustainLevelCommandChangesSteadyStateGain() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.0001, decayDuration: 0.0001, sustainLevel: 1.0))
    renderer.prepare(maxFrameCount: 4096)
    renderer.enqueue(.openGate)
    renderer.enqueue(.setSustainLevel(0.25))
    var buffer = [Float](repeating: -1, count: 4096)
    for _ in 0..<10 {
      buffer.withUnsafeMutableBufferPointer { renderer.render(into: $0, sampleRate: 44100) }
    }
    let steadyPeak = buffer.suffix(100).map { abs($0) }.max() ?? 0
    #expect(
      steadyPeak < 0.4,
      "sustain level lowered to 0.25 should cap steady-state amplitude well below the original 1.0 peak"
    )
  }

  @Test
  func setAttackDurationCommandChangesRampSpeed() {
    let slow = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1), envelope: EnvelopeDSP(attackDuration: 1.0))
    let fast = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1), envelope: EnvelopeDSP(attackDuration: 1.0))
    slow.prepare(maxFrameCount: 64)
    fast.prepare(maxFrameCount: 64)
    slow.enqueue(.openGate)
    fast.enqueue(.openGate)
    fast.enqueue(.setAttackDuration(0.0001))

    var slowBuffer = [Float](repeating: -1, count: 64)
    var fastBuffer = [Float](repeating: -1, count: 64)
    slowBuffer.withUnsafeMutableBufferPointer { slow.render(into: $0, sampleRate: 44100) }
    fastBuffer.withUnsafeMutableBufferPointer { fast.render(into: $0, sampleRate: 44100) }

    let slowPeak = slowBuffer.map { abs($0) }.max() ?? 0
    let fastPeak = fastBuffer.map { abs($0) }.max() ?? 0
    #expect(fastPeak > slowPeak, "a much faster attack should reach higher gain within the same short window")
  }

  @Test
  func setDecayDurationCommandChangesTimeToReachSustain() {
    let slow = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001, decayDuration: 1.0, sustainLevel: 0.2))
    let fast = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001, decayDuration: 1.0, sustainLevel: 0.2))
    slow.prepare(maxFrameCount: 64)
    fast.prepare(maxFrameCount: 64)
    slow.enqueue(.openGate)
    fast.enqueue(.openGate)
    fast.enqueue(.setDecayDuration(0.0001))

    var slowBuffer = [Float](repeating: -1, count: 64)
    var fastBuffer = [Float](repeating: -1, count: 64)
    slowBuffer.withUnsafeMutableBufferPointer { slow.render(into: $0, sampleRate: 44100) }
    fastBuffer.withUnsafeMutableBufferPointer { fast.render(into: $0, sampleRate: 44100) }

    let slowLast = abs(slowBuffer.last ?? 0)
    let fastLast = abs(fastBuffer.last ?? 0)
    #expect(
      fastLast < slowLast,
      "a much faster decay should have settled closer to the low sustain level within the same short window"
    )
  }

  @Test
  func setReleaseDurationCommandChangesTimeToSilence() {
    let slow = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001, releaseDuration: 1.0))
    let fast = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001, releaseDuration: 1.0))
    slow.prepare(maxFrameCount: 64)
    fast.prepare(maxFrameCount: 64)
    slow.enqueue(.openGate)
    fast.enqueue(.openGate)
    var warmupSlow = [Float](repeating: -1, count: 64)
    var warmupFast = [Float](repeating: -1, count: 64)
    warmupSlow.withUnsafeMutableBufferPointer { slow.render(into: $0, sampleRate: 44100) }
    warmupFast.withUnsafeMutableBufferPointer { fast.render(into: $0, sampleRate: 44100) }

    slow.enqueue(.closeGate)
    fast.enqueue(.closeGate)
    fast.enqueue(.setReleaseDuration(0.0001))

    var slowBuffer = [Float](repeating: -1, count: 64)
    var fastBuffer = [Float](repeating: -1, count: 64)
    slowBuffer.withUnsafeMutableBufferPointer { slow.render(into: $0, sampleRate: 44100) }
    fastBuffer.withUnsafeMutableBufferPointer { fast.render(into: $0, sampleRate: 44100) }

    let slowLast = abs(slowBuffer.last ?? 1)
    let fastLast = abs(fastBuffer.last ?? 1)
    #expect(fastLast < slowLast, "a much faster release should be closer to silence within the same short window")
  }
}
