//
//  Synthesizer.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation
import AudioToolbox
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

// A major improvement over the previous FM synthesizer!
@MainActor
final class Synthesizer {
  internal var isStarted = false
  private let engine = AudioEngine()
  private var currentFreq: Float = 0.0
  private var osc: Oscillator
  private var env: AmplitudeEnvelope
  private var fader: Fader
  private let defaultAmplitude = UserDefaults.standard.float(forKey: "synthAmplitude")

  /**
   * Create the synthesizer.
   * - Parameter autoStart: Automatically attempt to start the synthesizer on initialization.
   */
  init(autoStart: Bool = false) {
    osc = Oscillator()
    env = AmplitudeEnvelope(osc)
    fader = Fader(env)
    engine.output = fader
    osc.amplitude = defaultAmplitude
    env.attackDuration = UserDefaults.standard.float(forKey: "synthAttack")
    env.decayDuration = UserDefaults.standard.float(forKey: "synthDecay")
    env.sustainLevel = UserDefaults.standard.float(forKey: "synthSustain")
    env.releaseDuration = UserDefaults.standard.float(forKey: "synthRelease")
    // Start it automatically, if enabled.
    if autoStart {
      Task(priority: .high) { [self] in
        await self.start()
      }
    }
  }

  func start() async -> Result<Bool, Error> {
    guard !isStarted else {
      print("Engine already running.")
      return .success(true)
    }
    osc.start()
    do {
      try engine.start()
      isStarted = true
      return .success(true)
    } catch let err {
      print("Failed to start audio engine. Error: \(err)")
      return .failure(err)
    }
  }

  func shutdown() async {
    guard isStarted else { return }
    osc.stop()
    engine.stop()
  }

  func playNote(value: Int, range: ClosedRange<Int>, freqRange: ClosedRange<Float>, time: Float) async {
    // Cannot be replaced with await enforceRunning(); the Synthesizer class isn't an extension of the SortViewModel,
    // and I'm not putting an instance of SortViewModel into the parameters.
    guard !Task.isCancelled && isStarted else {
      if !isStarted {
        print("Refusing to play note; engine did not successfully start.")
      }
      return
    }
    let freq = floatRatio(x: Float(value),
                          oldRange: Float(range.lowerBound)...Float(range.upperBound),
                          newRange: freqRange)
    // Play the frequency/note.
    if freq != currentFreq {
      env.closeGate()
    }
    osc.frequency = freq
    env.openGate()
    // Wait the specified number of milliseconds, or 0.25 ms, because the notes will be functionally useless if they
    // are too short.
    let delay = UInt64(max(time * 1_000_000, 250_000))
    try? await Task.sleep(nanoseconds: delay)
    // Stop playing the note.
    env.closeGate()
  }

  func setMute(_ muted: Bool) async {
    osc.amplitude = muted ? 0.0 : defaultAmplitude
  }
}
