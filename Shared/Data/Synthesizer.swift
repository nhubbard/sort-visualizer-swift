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

// The normal range of MIDI notes that we want to use. In musical notation, this is equivalent to a range of C1 to C5.
let noteRange: ClosedRange<Int> = 36...72

// A major improvement over the previous FM synthesizer!
class Synthesizer {
    private var isStarted = false
    let engine = AudioEngine()
    var currentNote = 0
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
        // Convert note to closed range of specified MIDI notes.
        let note = UInt8(intRatio(x: value, oldRange: range, newRange: noteRange)) as MIDINoteNumber
        // Play the note.
        await noteOn(note: note)
        // Wait the specified number of milliseconds, or 1 ms, because the notes will be functionally useless if they are too short.
        let delay = UInt64(max(time * 1_000_000, 1_000_000))
        try? await Task.sleep(nanoseconds: delay)
        // Stop playing the note.
        await noteOff(note: note)
    }

    private func noteOn(note: MIDINoteNumber) async {
        if note != currentNote {
            env.closeGate()
        }
        // TODO: Instead of flattening it to a single note frequency, switch to the float-style flattening used before this transition.
        osc.frequency = note.midiNoteToFrequency()
        env.openGate()
    }

    private func noteOff(note: MIDINoteNumber) async {
        env.closeGate()
    }

    func shutdown() async {
        osc.stop()
        engine.stop()
    }
}
