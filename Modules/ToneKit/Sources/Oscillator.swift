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

import Accelerate
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
        // Reused across `fill` calls instead of allocated fresh each time — sized to match
        // whichever render-buffer frame count is actually in use, which in practice never changes
        // once `AVAudioEngine` picks a buffer size, so the common case allocates nothing at all on
        // the realtime audio thread. Both already `Mutex`-guarded by `state` alongside everything
        // else `fill` touches, so no separate synchronization is needed for them.
        var scratchPhases: [Double] = []
        var scratchSines: [Double] = []
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
    ///
    /// Vectorized via Accelerate rather than a per-sample `nextSample` loop: `sin` is exactly
    /// periodic and numerically accurate for any real input (no precision loss from letting phase
    /// run unwrapped across one buffer's worth of samples), so the whole buffer's phase ramp can be
    /// built and sined in bulk, with phase only wrapped back into `0..<2π` once at the end — one
    /// `vDSP`/`vForce` call each instead of a branch-per-sample scalar loop.
    func fill(_ buffer: UnsafeMutableBufferPointer<Float>, sampleRate: Double) {
        let count = buffer.count
        guard count > 0, let output = buffer.baseAddress else { return }
        state.withLock { s in
            if s.scratchPhases.count != count {
                s.scratchPhases = [Double](repeating: 0, count: count)
                s.scratchSines = [Double](repeating: 0, count: count)
            }
            let effectiveFrequency = Double(s.frequency) * Double(s.detuningMultiplier) + Double(s.detuningOffset)
            let increment = Self.phaseIncrement(frequency: effectiveFrequency, sampleRate: sampleRate)

            // phases[i] = s.phase + i * increment
            var start = s.phase
            var step = increment
            vDSP_vrampD(&start, &step, &s.scratchPhases, 1, vDSP_Length(count))

            // sines[i] = sin(phases[i])
            var n = Int32(count)
            vvsin(&s.scratchSines, s.scratchPhases, &n)

            // sines[i] *= amplitude, then narrowed straight into the Float output buffer.
            var amplitude = Double(s.amplitude)
            vDSP_vsmulD(s.scratchSines, 1, &amplitude, &s.scratchSines, 1, vDSP_Length(count))
            vDSP_vdpsp(s.scratchSines, 1, output, 1, vDSP_Length(count))

            s.phase = Self.wrappedPhase(start: s.phase, increment: increment, count: count)
        }
    }

    /// Pure sine-generation step — the scalar reference this file's `OscillatorTests` pin the math
    /// against, and what `fill` used to call directly per-sample before being vectorized above. Not
    /// dead code: every test in this file exercises the algorithm through these two functions
    /// specifically because they don't need a real realtime render context, matching
    /// `AudioService.frequency(forValue:in:noteRange:)`'s own "pure math, no live engine" split.
    static func phaseIncrement(frequency: Double, sampleRate: Double) -> Double {
        2 * Double.pi * frequency / sampleRate
    }

    static func nextSample(phase: Double, phaseIncrement: Double) -> (sample: Float, nextPhase: Double) {
        let sample = Float(sin(phase))
        var nextPhase = phase + phaseIncrement
        if nextPhase >= 2 * Double.pi { nextPhase -= 2 * Double.pi }
        return (sample, nextPhase)
    }

    /// Where `fill`'s per-sample wrap-if-past-2π check moved to: since nothing between here and the
    /// next `fill` call ever reads an intermediate phase, wrapping once at the very end of the
    /// buffer is equivalent to wrapping after every sample, and cheaper.
    static func wrappedPhase(start: Double, increment: Double, count: Int) -> Double {
        let twoPi = 2 * Double.pi
        let wrapped = (start + Double(count) * increment).truncatingRemainder(dividingBy: twoPi)
        return wrapped < 0 ? wrapped + twoPi : wrapped
    }
}
