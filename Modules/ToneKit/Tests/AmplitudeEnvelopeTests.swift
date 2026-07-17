import Testing

@testable import ToneKit

@Suite
struct AmplitudeEnvelopeTests {
  private let sampleRate = 44100.0

  /// Runs `nextGain` `count` times in a row, threading `phase` through each call — simulates
  /// what the render closure does one sample at a time, without needing a live `AVAudioEngine`.
  private func run(
    steps count: Int,
    startingGain: Float = 0,
    startingPhase: EnvelopePhase,
    attackDuration: Float = 0.1,
    decayDuration: Float = 0.1,
    sustainLevel: Float = 1.0,
    releaseDuration: Float = 0.1
  ) -> (gain: Float, phase: EnvelopePhase) {
    var gain = startingGain
    var phase = startingPhase
    for _ in 0..<count {
      gain = AmplitudeEnvelope.nextGain(
        currentGain: gain,
        phase: &phase,
        attackDuration: attackDuration,
        decayDuration: decayDuration,
        sustainLevel: sustainLevel,
        releaseDuration: releaseDuration,
        sampleRate: sampleRate
      )
    }
    return (gain, phase)
  }

  @Test
  func idlePhaseStaysSilentRegardlessOfStartingGain() {
    let result = run(steps: 10, startingGain: 0.5, startingPhase: .idle)
    #expect(result.gain == 0)
    #expect(result.phase == .idle)
  }

  @Test
  func attackRisesTowardFullGainThenAdvancesToDecay() {
    // Crossing the 0.999 threshold needs gain = 1 - e^-x = 0.999 -> x = ln(1000) ≈ 6.9 time
    // constants. At a 0.1s attack and 44.1kHz, that's ~30,400 samples — 50,000 clears it with
    // real margin (≈11.3 time constants, 1 - e^-11.3 ≈ 0.9999875).
    let result = run(steps: 50_000, startingPhase: .attack)
    #expect(result.phase == .decay, "expected attack to hand off to decay once gain settled near 1")
    #expect(result.gain > 0.99)
  }

  @Test
  func decaySettlesAtSustainLevelNotFullGain() {
    let result = run(steps: 20_000, startingGain: 1.0, startingPhase: .decay, sustainLevel: 0.5)
    #expect(abs(result.gain - 0.5) < 0.01)
    // Decay has no further phase to advance to on its own — it stays parked at sustain until
    // a real closeGate() (a phase change from outside nextGain) switches it to release.
    #expect(result.phase == .decay)
  }

  @Test
  func decayIsANoOpWhenSustainLevelIsFullGain() {
    // AudioService always constructs its envelope with sustainLevel: 1.0 — decay's target
    // equals attack's target, so it should hold, not dip and climb back.
    let result = run(steps: 5_000, startingGain: 1.0, startingPhase: .decay, sustainLevel: 1.0)
    #expect(abs(result.gain - 1.0) < 0.0001)
  }

  @Test
  func releaseFallsToSilenceThenAdvancesToIdle() {
    // Crossing the 0.0001 threshold needs gain = e^-x = 0.0001 -> x = ln(10000) ≈ 9.2 time
    // constants (~40,600 samples at a 0.1s release, 44.1kHz) — 50,000 clears it with margin.
    let result = run(steps: 50_000, startingGain: 1.0, startingPhase: .release)
    #expect(result.phase == .idle, "expected release to settle into idle once gain neared 0")
    #expect(result.gain == 0)
  }

  @Test
  func singleStepMovesTowardTargetNotAwayFromIt() {
    var phase = EnvelopePhase.attack
    let gain = AmplitudeEnvelope.nextGain(
      currentGain: 0, phase: &phase,
      attackDuration: 0.1, decayDuration: 0.1, sustainLevel: 1.0, releaseDuration: 0.1,
      sampleRate: sampleRate
    )
    #expect(gain > 0, "attack's target is 1.0, so a single step from 0 should move upward")
    #expect(
      phase == .attack,
      "one step at a 0.1s time constant shouldn't already cross the 0.999 threshold")
  }

  @Test
  func longerAttackDurationRisesMoreSlowlyThanShorterOne() {
    let fast = run(steps: 100, startingPhase: .attack, attackDuration: 0.01)
    let slow = run(steps: 100, startingPhase: .attack, attackDuration: 1.0)
    #expect(
      fast.gain > slow.gain,
      "a shorter attack time constant should reach a higher gain in the same steps")
  }
}
