import Testing

@testable import ToneKitDSP

/// Same "test the pure math, not a live audio graph" split `AudioServiceTests.swift` already
/// uses for `AudioService.frequency(forValue:in:noteRange:)` — `OscillatorDSP.fill` needs a
/// realtime render context to exercise fully, but its underlying per-sample math
/// (`nextSample`/`phaseIncrement`) doesn't, so that's what's checked here.
@Suite
struct OscillatorDSPTests {
  @Test
  func phaseIncrementScalesLinearlyWithFrequency() {
    let increment = OscillatorDSP.phaseIncrement(frequency: 440, sampleRate: 44100)
    #expect(abs(increment - (2 * Double.pi * 440 / 44100)) < 0.00001)
  }

  @Test
  func nextSampleAtZeroPhaseIsZero() {
    let (sample, _) = OscillatorDSP.nextSample(phase: 0, phaseIncrement: 0.1)
    #expect(abs(sample) < 0.0001)
  }

  @Test
  func nextSampleAtQuarterPeriodIsPeakAmplitude() {
    let (sample, _) = OscillatorDSP.nextSample(phase: .pi / 2, phaseIncrement: 0.1)
    #expect(abs(sample - 1.0) < 0.0001)
  }

  @Test
  func nextSampleWrapsPhasePastTwoPi() {
    let increment = 0.1
    let (_, nextPhase) = OscillatorDSP.nextSample(
      phase: 2 * Double.pi - 0.05, phaseIncrement: increment)
    #expect(nextPhase >= 0)
    #expect(nextPhase < 2 * Double.pi)
    #expect(abs(nextPhase - 0.05) < 0.0001)
  }

  @Test
  func fillProducesOneSamplePerFrameScaledByAmplitude() {
    // Hard-left pan makes the left channel's gain exactly 1 (equal-power gain at the pan extreme),
    // so it reproduces the un-panned single-buffer math these amplitude assertions check. A
    // throwaway warm-up call lets the pan ramp (declicking — see `applyRampedScale`) finish
    // settling into hard-left before the buffer under test, so these assertions see the steady
    // state rather than the transition into it.
    var osc = OscillatorDSP(frequency: 440, amplitude: 0.5)
    osc.pan = -1
    osc.prepare(maxFrameCount: 8)
    var warmup = [Float](repeating: -1, count: 8)
    var warmupRight = [Float](repeating: -1, count: 8)
    warmup.withUnsafeMutableBufferPointer { l in
      warmupRight.withUnsafeMutableBufferPointer { r in osc.fill(left: l, right: r, sampleRate: 44100) }
    }

    var left = [Float](repeating: -1, count: 8)
    var right = [Float](repeating: -1, count: 8)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in osc.fill(left: l, right: r, sampleRate: 44100) }
    }

    // The warm-up call already advanced phase past 0, so (unlike the un-warmed-up tests below)
    // this only checks the amplitude bound, not any specific sample value.
    #expect(left.allSatisfy { abs($0) <= 0.5 + 0.0001 })
    #expect(right.allSatisfy { abs($0) < 0.0001 })
  }

  @Test
  func fillRampsTheScaleAcrossABufferInsteadOfJumpingInstantly() {
    // A pan flip mid-stream (hard-left -> hard-right) should NOT make the very next buffer's
    // right channel jump straight to full amplitude — it should start near where the ramp began
    // (near-silent, since the previous buffer was hard-left) and grow across the buffer. This is
    // the actual declicking behavior: a real per-buffer amplitude jump is what produced the
    // reported "low-frequency crackling."
    //
    // `frequency` is set to 0 for the buffer under test so every raw sample holds the same
    // (whatever nonzero phase the warm-up call left behind) value — isolating the ramp's own
    // effect from the sine wave's own natural variation across the buffer.
    var osc = OscillatorDSP(frequency: 440, amplitude: 1)
    osc.pan = -1
    osc.prepare(maxFrameCount: 256)
    var warmup = [Float](repeating: -1, count: 256)
    var warmupRight = [Float](repeating: -1, count: 256)
    warmup.withUnsafeMutableBufferPointer { l in
      warmupRight.withUnsafeMutableBufferPointer { r in osc.fill(left: l, right: r, sampleRate: 44100) }
    }

    osc.pan = 1
    osc.frequency = 0
    var right = [Float](repeating: -1, count: 256)
    var left = [Float](repeating: -1, count: 256)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in osc.fill(left: l, right: r, sampleRate: 44100) }
    }

    #expect(
      abs(right[0]) < abs(right[right.count - 1]),
      "right channel should ramp up toward full amplitude across the buffer, not start there")
  }

  @Test
  func fillAdvancesPhaseAcrossCallsInsteadOfRestartingEachTime() {
    var osc = OscillatorDSP(frequency: 440, amplitude: 1)
    osc.pan = -1
    osc.prepare(maxFrameCount: 4)
    var first = [Float](repeating: 0, count: 4)
    var firstRight = [Float](repeating: 0, count: 4)
    var second = [Float](repeating: 0, count: 4)
    var secondRight = [Float](repeating: 0, count: 4)
    first.withUnsafeMutableBufferPointer { l in
      firstRight.withUnsafeMutableBufferPointer { r in
        osc.fill(left: l, right: r, sampleRate: 44100)
      }
    }
    second.withUnsafeMutableBufferPointer { l in
      secondRight.withUnsafeMutableBufferPointer { r in
        osc.fill(left: l, right: r, sampleRate: 44100)
      }
    }

    // The second call's first sample continues the waveform from where the first call left
    // off — it should not restart at phase 0 (sample 0) like the very first call did.
    #expect(abs(first[0]) < 0.0001)
    #expect(abs(second[0]) > 0.0001)
  }

  @Test
  func detuningOffsetAndMultiplierAffectEffectiveFrequency() {
    var plain = OscillatorDSP(frequency: 440)
    var detuned = OscillatorDSP(frequency: 440, detuningOffset: 100, detuningMultiplier: 1)
    plain.pan = -1
    detuned.pan = -1
    plain.prepare(maxFrameCount: 4)
    detuned.prepare(maxFrameCount: 4)
    var plainBuffer = [Float](repeating: 0, count: 4)
    var plainRight = [Float](repeating: 0, count: 4)
    var detunedBuffer = [Float](repeating: 0, count: 4)
    var detunedRight = [Float](repeating: 0, count: 4)
    plainBuffer.withUnsafeMutableBufferPointer { l in
      plainRight.withUnsafeMutableBufferPointer { r in
        plain.fill(left: l, right: r, sampleRate: 44100)
      }
    }
    detunedBuffer.withUnsafeMutableBufferPointer { l in
      detunedRight.withUnsafeMutableBufferPointer { r in
        detuned.fill(left: l, right: r, sampleRate: 44100)
      }
    }

    // Both start at phase 0 (identical first sample), but a 100Hz-higher effective frequency
    // must diverge from the plain oscillator by the second sample.
    #expect(abs(plainBuffer[0] - detunedBuffer[0]) < 0.0001)
    #expect(abs(plainBuffer[1] - detunedBuffer[1]) > 0.0001)
  }

  @Test
  func fillClampsToPreparedCapacityInsteadOfAllocating() {
    // Preparing for fewer frames than a later `fill` call requests must not resize scratch
    // storage on the fly — the excess renders as silence instead (Documentation/docs/architecture/audio.md's "no
    // allocation on the render thread" rule, applied even to a misconfigured `prepare` call).
    var osc = OscillatorDSP(frequency: 440, amplitude: 1)
    osc.prepare(maxFrameCount: 2)
    var left = [Float](repeating: -1, count: 4)
    var right = [Float](repeating: -1, count: 4)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in osc.fill(left: l, right: r, sampleRate: 44100) }
    }
    #expect(left[2] == 0)
    #expect(left[3] == 0)
    #expect(right[2] == 0)
    #expect(right[3] == 0)
  }

  @Test
  func equalPowerPanGainsAreEqualAtCenterAndExtremeAtHardSides() {
    let center = OscillatorDSP.equalPowerPanGains(pan: 0)
    #expect(abs(center.left - center.right) < 0.0001)
    #expect(abs(center.left * center.left + center.right * center.right - 1) < 0.0001)

    let hardLeft = OscillatorDSP.equalPowerPanGains(pan: -1)
    #expect(abs(hardLeft.left - 1) < 0.0001)
    #expect(abs(hardLeft.right) < 0.0001)

    let hardRight = OscillatorDSP.equalPowerPanGains(pan: 1)
    #expect(abs(hardRight.left) < 0.0001)
    #expect(abs(hardRight.right - 1) < 0.0001)
  }
}
