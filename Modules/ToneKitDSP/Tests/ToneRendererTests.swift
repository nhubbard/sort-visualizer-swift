import Testing

@testable import ToneKitDSP

@Suite
struct ToneRendererTests {
  @Test
  func renderIsSilentUntilGateOpens() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1), envelope: EnvelopeDSP())
    renderer.prepare(maxFrameCount: 8)
    var left = [Float](repeating: -1, count: 8)
    var right = [Float](repeating: -1, count: 8)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }
    #expect(left.allSatisfy { $0 == 0 }, "gate never opened, so gain should stay 0 throughout")
    #expect(right.allSatisfy { $0 == 0 })
  }

  @Test
  func openGateCommandRampsGainUpFromZero() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.001))
    renderer.prepare(maxFrameCount: 512)
    renderer.enqueue(.openGate)
    var left = [Float](repeating: -1, count: 512)
    var right = [Float](repeating: -1, count: 512)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }
    #expect(!left.allSatisfy { $0 == 0 }, "an open gate should let some nonzero samples through")
  }

  @Test
  func closeGateCommandEventuallySilencesOutputAgain() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.0001, releaseDuration: 0.0001))
    renderer.prepare(maxFrameCount: 4096)
    renderer.enqueue(.openGate)
    var opened = [Float](repeating: -1, count: 4096)
    var openedRight = [Float](repeating: -1, count: 4096)
    opened.withUnsafeMutableBufferPointer { l in
      openedRight.withUnsafeMutableBufferPointer { r in
        renderer.render(left: l, right: r, sampleRate: 44100)
      }
    }
    #expect(!opened.allSatisfy { $0 == 0 })

    renderer.enqueue(.closeGate)
    // Several buffers of release time at a 0.0001s time constant and 44.1kHz settle to silence
    // well within this many samples.
    var closed = [Float](repeating: -1, count: 4096)
    var closedRight = [Float](repeating: -1, count: 4096)
    for _ in 0..<10 {
      closed.withUnsafeMutableBufferPointer { l in
        closedRight.withUnsafeMutableBufferPointer { r in
          renderer.render(left: l, right: r, sampleRate: 44100)
        }
      }
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
    var unchangedRight = [Float](repeating: -1, count: 4)
    var changedBuffer = [Float](repeating: -1, count: 4)
    var changedRight = [Float](repeating: -1, count: 4)
    unchangedBuffer.withUnsafeMutableBufferPointer { l in
      unchangedRight.withUnsafeMutableBufferPointer { r in
        unchanged.render(left: l, right: r, sampleRate: 44100)
      }
    }
    changedBuffer.withUnsafeMutableBufferPointer { l in
      changedRight.withUnsafeMutableBufferPointer { r in
        changed.render(left: l, right: r, sampleRate: 44100)
      }
    }

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

    // Warm-up call lets halved's amplitude-change ramp (declicking — see `applyRampedScale`)
    // finish settling to its new target before the buffer under test, so the peak comparison
    // below sees the steady state rather than a transition still descending from full amplitude.
    var warmupFull = [Float](repeating: 0, count: 512)
    var warmupFullRight = [Float](repeating: 0, count: 512)
    var warmupHalved = [Float](repeating: 0, count: 512)
    var warmupHalvedRight = [Float](repeating: 0, count: 512)
    warmupFull.withUnsafeMutableBufferPointer { l in
      warmupFullRight.withUnsafeMutableBufferPointer { r in full.render(left: l, right: r, sampleRate: 44100) }
    }
    warmupHalved.withUnsafeMutableBufferPointer { l in
      warmupHalvedRight.withUnsafeMutableBufferPointer { r in
        halved.render(left: l, right: r, sampleRate: 44100)
      }
    }

    var fullBuffer = [Float](repeating: 0, count: 512)
    var fullRight = [Float](repeating: 0, count: 512)
    var halvedBuffer = [Float](repeating: 0, count: 512)
    var halvedRight = [Float](repeating: 0, count: 512)
    fullBuffer.withUnsafeMutableBufferPointer { l in
      fullRight.withUnsafeMutableBufferPointer { r in full.render(left: l, right: r, sampleRate: 44100) }
    }
    halvedBuffer.withUnsafeMutableBufferPointer { l in
      halvedRight.withUnsafeMutableBufferPointer { r in
        halved.render(left: l, right: r, sampleRate: 44100)
      }
    }

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
    var unchangedRight = [Float](repeating: -1, count: 4)
    var detunedBuffer = [Float](repeating: -1, count: 4)
    var detunedRight = [Float](repeating: -1, count: 4)
    unchangedBuffer.withUnsafeMutableBufferPointer { l in
      unchangedRight.withUnsafeMutableBufferPointer { r in
        unchanged.render(left: l, right: r, sampleRate: 44100)
      }
    }
    detunedBuffer.withUnsafeMutableBufferPointer { l in
      detunedRight.withUnsafeMutableBufferPointer { r in
        detuned.render(left: l, right: r, sampleRate: 44100)
      }
    }

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
    var bufferRight = [Float](repeating: -1, count: 4096)
    for _ in 0..<10 {
      buffer.withUnsafeMutableBufferPointer { l in
        bufferRight.withUnsafeMutableBufferPointer { r in
          renderer.render(left: l, right: r, sampleRate: 44100)
        }
      }
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
    var slowRight = [Float](repeating: -1, count: 64)
    var fastBuffer = [Float](repeating: -1, count: 64)
    var fastRight = [Float](repeating: -1, count: 64)
    slowBuffer.withUnsafeMutableBufferPointer { l in
      slowRight.withUnsafeMutableBufferPointer { r in slow.render(left: l, right: r, sampleRate: 44100) }
    }
    fastBuffer.withUnsafeMutableBufferPointer { l in
      fastRight.withUnsafeMutableBufferPointer { r in fast.render(left: l, right: r, sampleRate: 44100) }
    }

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
    var slowRight = [Float](repeating: -1, count: 64)
    var fastBuffer = [Float](repeating: -1, count: 64)
    var fastRight = [Float](repeating: -1, count: 64)
    slowBuffer.withUnsafeMutableBufferPointer { l in
      slowRight.withUnsafeMutableBufferPointer { r in slow.render(left: l, right: r, sampleRate: 44100) }
    }
    fastBuffer.withUnsafeMutableBufferPointer { l in
      fastRight.withUnsafeMutableBufferPointer { r in fast.render(left: l, right: r, sampleRate: 44100) }
    }

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
    var warmupSlowRight = [Float](repeating: -1, count: 64)
    var warmupFast = [Float](repeating: -1, count: 64)
    var warmupFastRight = [Float](repeating: -1, count: 64)
    warmupSlow.withUnsafeMutableBufferPointer { l in
      warmupSlowRight.withUnsafeMutableBufferPointer { r in
        slow.render(left: l, right: r, sampleRate: 44100)
      }
    }
    warmupFast.withUnsafeMutableBufferPointer { l in
      warmupFastRight.withUnsafeMutableBufferPointer { r in
        fast.render(left: l, right: r, sampleRate: 44100)
      }
    }

    slow.enqueue(.closeGate)
    fast.enqueue(.closeGate)
    fast.enqueue(.setReleaseDuration(0.0001))

    var slowBuffer = [Float](repeating: -1, count: 64)
    var slowRight = [Float](repeating: -1, count: 64)
    var fastBuffer = [Float](repeating: -1, count: 64)
    var fastRight = [Float](repeating: -1, count: 64)
    slowBuffer.withUnsafeMutableBufferPointer { l in
      slowRight.withUnsafeMutableBufferPointer { r in slow.render(left: l, right: r, sampleRate: 44100) }
    }
    fastBuffer.withUnsafeMutableBufferPointer { l in
      fastRight.withUnsafeMutableBufferPointer { r in fast.render(left: l, right: r, sampleRate: 44100) }
    }

    let slowLast = abs(slowBuffer.last ?? 1)
    let fastLast = abs(fastBuffer.last ?? 1)
    #expect(fastLast < slowLast, "a much faster release should be closer to silence within the same short window")
  }

  @Test
  func setPanCommandHardLeftSilencesTheRightChannel() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    renderer.prepare(maxFrameCount: 256)
    renderer.enqueue(.openGate)
    renderer.enqueue(.setPan(-1))

    // Warm-up call lets the pan ramp (declicking) finish settling into hard-left before the
    // buffer under test, so `allSatisfy` sees the steady state rather than the transition into it.
    var warmup = [Float](repeating: -1, count: 256)
    var warmupRight = [Float](repeating: -1, count: 256)
    warmup.withUnsafeMutableBufferPointer { l in
      warmupRight.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }

    var left = [Float](repeating: -1, count: 256)
    var right = [Float](repeating: -1, count: 256)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }

    #expect(!left.allSatisfy { $0 == 0 })
    #expect(right.allSatisfy { abs($0) < 0.0001 }, "hard-left pan should produce silence on the right channel")
  }

  @Test
  func setPanCommandHardRightSilencesTheLeftChannel() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    renderer.prepare(maxFrameCount: 256)
    renderer.enqueue(.openGate)
    renderer.enqueue(.setPan(1))

    // See the hard-left test's comment above for why this warm-up call is here.
    var warmup = [Float](repeating: -1, count: 256)
    var warmupRight = [Float](repeating: -1, count: 256)
    warmup.withUnsafeMutableBufferPointer { l in
      warmupRight.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }

    var left = [Float](repeating: -1, count: 256)
    var right = [Float](repeating: -1, count: 256)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }

    #expect(left.allSatisfy { abs($0) < 0.0001 }, "hard-right pan should produce silence on the left channel")
    #expect(!right.allSatisfy { $0 == 0 })
  }

  @Test
  func setPanCommandCenteredProducesRoughlyEqualEnergyOnBothChannels() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.00001))
    renderer.prepare(maxFrameCount: 256)
    renderer.enqueue(.openGate)
    renderer.enqueue(.setPan(0))

    var left = [Float](repeating: -1, count: 256)
    var right = [Float](repeating: -1, count: 256)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }

    let leftPeak = left.map { abs($0) }.max() ?? 0
    let rightPeak = right.map { abs($0) }.max() ?? 0
    #expect(leftPeak > 0)
    #expect(abs(leftPeak - rightPeak) < 0.01, "center pan should produce roughly equal peak energy on both channels")
  }
}
