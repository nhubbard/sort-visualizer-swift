//
//  NewSynth.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation
import AudioToolbox
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

// The frequency range from the lowest MIDI note to the highest MIDI note. 36 is C2 and 72 is C5.
let floatFrequencyRange = UInt8(36).midiNoteToFrequency()...UInt8(72).midiNoteToFrequency()

// A major improvement over the previous FM synthesizer!
@MainActor
final class Synthesizer: Sendable {
  private var isStarted = false
  private let engine = AudioEngine()
  private var currentFreq: Float = 0.0
  private var osc: Oscillator
  private var env: AmplitudeEnvelope
  private var fader: Fader
  
  /**
   * Create the synthesizer.
   * - Parameter autoStart: Automatically attempt to start the synthesizer on initialization.
   */
  init(autoStart: Bool = false) {
    osc = Oscillator()
    env = AmplitudeEnvelope(osc)
    fader = Fader(env)
    osc.amplitude = 1
    engine.output = fader
    // Tuned manually using a modified version of the AudioKit Cookbook app.
    // (Not really, I took most of the default values because I thought they sounded good.)
    env.attackDuration = 0.5
    env.decayDuration = 0.5
    env.sustainLevel = 0.5
    env.releaseDuration = 0.5
    // Start it automatically, if enabled.
    if autoStart {
      Task { [self] in
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
  
  func playNote(value: Int, range: ClosedRange<Int>, time: Float) async {
    // Cannot be replaced with await enforceRunning(); the Synthesizer class isn't an extension of the SortViewModel, and I'm not putting an instance of SortViewModel into the parameters.
    guard !Task.isCancelled && isStarted else {
      if !isStarted {
        print("Refusing to play note; engine did not successfully start.")
      }
      return
    }
    // Convert the index to the frequency within the range of C1 to C5.
    let freq = floatRatio(x: Float(value), oldRange: Float(range.lowerBound)...Float(range.upperBound), newRange: floatFrequencyRange)
    // Play the frequency/note.
    if freq != currentFreq {
      env.closeGate()
    }
    osc.frequency = freq
    env.openGate()
    // Wait the specified number of milliseconds, or 0.25 ms, because the notes will be functionally useless if they are too short.
    let delay = UInt64(max(time * 1_000_000, 250_000))
    try? await Task.sleep(nanoseconds: delay)
    // Stop playing the note.
    env.closeGate()
  }
}
