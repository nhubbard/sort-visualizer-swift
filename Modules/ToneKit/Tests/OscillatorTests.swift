import Testing

@testable import ToneKit

/// Same "test the pure math, not a live audio graph" split `AudioServiceTests.swift` already
/// uses for `AudioService.frequency(forValue:in:noteRange:)` — `Oscillator.fill` needs a real
/// realtime render context to exercise directly, but its underlying per-sample math
/// (`nextSample`/`phaseIncrement`) doesn't, so that's what's checked here.
@Suite
struct OscillatorTests {
  @Test
  func phaseIncrementScalesLinearlyWithFrequency() {
    let increment = Oscillator.phaseIncrement(frequency: 440, sampleRate: 44100)
    #expect(abs(increment - (2 * Double.pi * 440 / 44100)) < 0.00001)
  }

  @Test
  func nextSampleAtZeroPhaseIsZero() {
    let (sample, _) = Oscillator.nextSample(phase: 0, phaseIncrement: 0.1)
    #expect(abs(sample) < 0.0001)
  }

  @Test
  func nextSampleAtQuarterPeriodIsPeakAmplitude() {
    let (sample, _) = Oscillator.nextSample(phase: .pi / 2, phaseIncrement: 0.1)
    #expect(abs(sample - 1.0) < 0.0001)
  }

  @Test
  func nextSampleWrapsPhasePastTwoPi() {
    let increment = 0.1
    let (_, nextPhase) = Oscillator.nextSample(
      phase: 2 * Double.pi - 0.05, phaseIncrement: increment)
    #expect(nextPhase >= 0)
    #expect(nextPhase < 2 * Double.pi)
    #expect(abs(nextPhase - 0.05) < 0.0001)
  }

  @Test
  func fillProducesOneSamplePerFrameScaledByAmplitude() {
    let osc = Oscillator(frequency: 440, amplitude: 0.5)
    var buffer = [Float](repeating: -1, count: 8)
    buffer.withUnsafeMutableBufferPointer { osc.fill($0, sampleRate: 44100) }

    // First sample is always phase 0 -> sin(0) = 0, regardless of amplitude.
    #expect(abs(buffer[0]) < 0.0001)
    #expect(buffer.allSatisfy { abs($0) <= 0.5 + 0.0001 })
  }

  @Test
  func fillAdvancesPhaseAcrossCallsInsteadOfRestartingEachTime() {
    let osc = Oscillator(frequency: 440, amplitude: 1)
    var first = [Float](repeating: 0, count: 4)
    var second = [Float](repeating: 0, count: 4)
    first.withUnsafeMutableBufferPointer { osc.fill($0, sampleRate: 44100) }
    second.withUnsafeMutableBufferPointer { osc.fill($0, sampleRate: 44100) }

    // The second call's first sample continues the waveform from where the first call left
    // off — it should not restart at phase 0 (sample 0) like the very first call did.
    #expect(abs(first[0]) < 0.0001)
    #expect(abs(second[0]) > 0.0001)
  }

  @Test
  func detuningOffsetAndMultiplierAffectEffectiveFrequency() {
    let plain = Oscillator(frequency: 440)
    let detuned = Oscillator(frequency: 440, detuningOffset: 100, detuningMultiplier: 1)
    var plainBuffer = [Float](repeating: 0, count: 4)
    var detunedBuffer = [Float](repeating: 0, count: 4)
    plainBuffer.withUnsafeMutableBufferPointer { plain.fill($0, sampleRate: 44100) }
    detunedBuffer.withUnsafeMutableBufferPointer { detuned.fill($0, sampleRate: 44100) }

    // Both start at phase 0 (identical first sample), but a 100Hz-higher effective frequency
    // must diverge from the plain oscillator by the second sample.
    #expect(abs(plainBuffer[0] - detunedBuffer[0]) < 0.0001)
    #expect(abs(plainBuffer[1] - detunedBuffer[1]) > 0.0001)
  }
}
