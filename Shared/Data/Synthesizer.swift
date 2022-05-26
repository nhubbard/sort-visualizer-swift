//
//  NewSynth.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation
import AudioToolbox
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

// The frequency range from the lowest MIDI note to the highest MIDI note. 36 is C1 and 72 is C5.
let floatFrequencyRange = UInt8(36).midiNoteToFrequency()...UInt8(72).midiNoteToFrequency()

// A major improvement over the previous FM synthesizer!
class Synthesizer {
    private var isStarted = false
    let engine = AudioEngine()
    var currentFreq: Float = 0.0
    var osc: Oscillator
    var env: AmplitudeEnvelope
    var fader: Fader
    
    init() {
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
        // Start it automatically.
        osc.start()
        do {
            try engine.start()
            isStarted = true
        } catch let err {
            print("Failed to start audio engine. Error: \(err)")
        }
    }
    
    func playNote(value: Int, range: ClosedRange<Int>, time: Float) async {
        guard !Task.isCancelled else {
            return
        }
        // Only play the note if the system is started correctly.
        guard isStarted else {
            print("Refusing to play note; engine did not successfully start.")
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
        // Wait the specified number of milliseconds, or 1 ms, because the notes will be functionally useless if they are too short.
        let delay = UInt64(max(time * 1_000_000, 1_000_000))
        try? await Task.sleep(nanoseconds: delay)
        // Stop playing the note.
        env.closeGate()
    }

    func shutdown() async {
        osc.stop()
        engine.stop()
    }
}
