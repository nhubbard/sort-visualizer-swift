// This file's public API (`frequency`/`amplitude`/`detuningOffset`/`detuningMultiplier`) is
// modeled on SoundpipeAudioKit's `Oscillator` (github.com/AudioKit/SoundpipeAudioKit,
// Generators/Oscillator.swift) — reduced to a plain sine wave (no waveform table selection) and
// reimplemented as a direct phase accumulator instead of a wrapped native Soundpipe "oscl" Audio
// Unit. See this module's NOTICE.md.
//
// Used under the MIT License:
//
// MIT License
//
// Copyright (c) 2016 Aurelius Prochazka (AudioKit)
// Copyright (c) 2021 AudioKit (AudioKitEX, SoundpipeAudioKit)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Synchronization

/// A single sine voice. Not itself an `AVAudioNode`/`Node` — unlike AudioKit's real `Oscillator`,
/// which gets its own Audio Unit so it can be wired into an arbitrary graph, this one is always
/// the innermost link in exactly one chain (`AmplitudeEnvelope` owns the actual `AVAudioSourceNode`
/// and pulls samples from this directly), so it doesn't need graph machinery of its own.
///
/// `frequency`/`amplitude`/`detuningOffset`/`detuningMultiplier` are set from `@MainActor` code
/// (`AudioService`) but read every render buffer from the realtime audio thread — `Mutex`-guarded
/// so both sides are safe without exposing any lock to callers.
public final class Oscillator: Sendable {
    struct State: Sendable {
        var frequency: Float
        var amplitude: Float
        var detuningOffset: Float
        var detuningMultiplier: Float
        var phase: Double = 0
    }

    private let state: Mutex<State>

    public init(
        frequency: Float = 440.0,
        amplitude: Float = 1.0,
        detuningOffset: Float = 0.0,
        detuningMultiplier: Float = 1.0
    ) {
        state = Mutex(State(
            frequency: frequency,
            amplitude: amplitude,
            detuningOffset: detuningOffset,
            detuningMultiplier: detuningMultiplier
        ))
    }

    public var frequency: Float {
        get { state.withLock { $0.frequency } }
        set { state.withLock { $0.frequency = newValue } }
    }

    public var amplitude: Float {
        get { state.withLock { $0.amplitude } }
        set { state.withLock { $0.amplitude = newValue } }
    }

    public var detuningOffset: Float {
        get { state.withLock { $0.detuningOffset } }
        set { state.withLock { $0.detuningOffset = newValue } }
    }

    public var detuningMultiplier: Float {
        get { state.withLock { $0.detuningMultiplier } }
        set { state.withLock { $0.detuningMultiplier = newValue } }
    }

    /// One lock acquisition per call, not per sample — this runs on the realtime audio thread once
    /// per render buffer (typically a few hundred frames), so a single short critical section here
    /// keeps contention negligible regardless of buffer size.
    func fill(_ buffer: UnsafeMutableBufferPointer<Float>, sampleRate: Double) {
        state.withLock { s in
            let effectiveFrequency = Double(s.frequency) * Double(s.detuningMultiplier) + Double(s.detuningOffset)
            let phaseIncrement = Self.phaseIncrement(frequency: effectiveFrequency, sampleRate: sampleRate)
            for i in buffer.indices {
                let (sample, nextPhase) = Self.nextSample(phase: s.phase, phaseIncrement: phaseIncrement)
                buffer[i] = sample * s.amplitude
                s.phase = nextPhase
            }
        }
    }

    /// Pure sine-generation step, pulled out of `fill` for direct testability (matching
    /// `AudioService.frequency(forValue:in:noteRange:)`'s own "pure math, no live engine" split).
    static func phaseIncrement(frequency: Double, sampleRate: Double) -> Double {
        2 * Double.pi * frequency / sampleRate
    }

    static func nextSample(phase: Double, phaseIncrement: Double) -> (sample: Float, nextPhase: Double) {
        let sample = Float(sin(phase))
        var nextPhase = phase + phaseIncrement
        if nextPhase >= 2 * Double.pi { nextPhase -= 2 * Double.pi }
        return (sample, nextPhase)
    }
}
