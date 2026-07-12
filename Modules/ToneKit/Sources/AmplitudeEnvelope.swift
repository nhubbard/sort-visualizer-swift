// This file's public API (`Gated`'s `openGate`/`closeGate`, `AmplitudeEnvelope`'s
// attack/decay/sustain/release parameters) is modeled on AudioKitEX (github.com/AudioKit/AudioKitEX,
// Node+Triggerable.swift's `Gated`) and SoundpipeAudioKit (github.com/AudioKit/SoundpipeAudioKit,
// Effects/AmplitudeEnvelope.swift). The envelope *shape* — a one-pole exponential filter chasing a
// target level, rather than a linear ramp — is modeled on (not copied from) Soundpipe's own C
// kernel behind SoundpipeAudioKit's `AmplitudeEnvelope` (Sources/Soundpipe/modules/adsr.c,
// `sp_adsr_compute`): same `pole = exp(-1 / (tau * sampleRate))` one-pole-filter idea, without
// copying Soundpipe's specific per-sample state machine (its attack-time fudge factor, manual
// timer counting, and lack of an explicit sustain/idle exit are all Soundpipe implementation
// details, not part of the audible behavior `AudioService` actually depends on). See this module's
// NOTICE.md.
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

import AVFoundation
import CoreAudio
import Synchronization

/// To allow a node to be gated open/closed — matches AudioKitEX's own protocol shape exactly.
public protocol Gated: AnyObject {
    func openGate()
    func closeGate()
}

enum EnvelopePhase: Sendable, Equatable {
    case idle, attack, decay, release
}

/// Triggerable attack/decay/sustain/release envelope, applied to a wrapped `Oscillator`. Owns the
/// actual `AVAudioSourceNode` — the terminal node in this module's one signal chain — pulling raw
/// samples from `Oscillator.fill` and multiplying by the current envelope gain in the same render
/// pass, since `AVAudioSourceNode` can only be a *source*, not an insertable effect: there's no way
/// to give the oscillator its own node and have this one process that node's output, short of a
/// custom Audio Unit. One real voice, one real node — matching what `AudioService` actually needs.
public final class AmplitudeEnvelope: Node, Gated {
    struct State: Sendable {
        var phase: EnvelopePhase = .idle
        var gateOpen = false
        var gain: Float = 0
        var attackDuration: Float
        var decayDuration: Float
        var sustainLevel: Float
        var releaseDuration: Float
    }

    /// `Mutex` is itself a noncopyable type (SE-0433) — it can't be captured directly by an
    /// escaping closure, only a class *holding* one can (a class instance is an ordinary ARC
    /// reference, copyable regardless of what noncopyable value lives inside it). This box is that
    /// class: it's what the render closure below actually captures, not the bare `Mutex`.
    private final class StateBox: Sendable {
        let mutex: Mutex<State>
        init(_ state: State) { mutex = Mutex(state) }
    }

    private let stateBox: StateBox
    public let avAudioNode: AVAudioNode
    public let outputFormat: AVAudioFormat

    public init(
        _ input: Oscillator,
        attackDuration: Float = 0.1,
        decayDuration: Float = 0.1,
        sustainLevel: Float = 1.0,
        releaseDuration: Float = 0.1,
        format: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    ) {
        let stateBox = StateBox(State(
            attackDuration: attackDuration,
            decayDuration: decayDuration,
            sustainLevel: sustainLevel,
            releaseDuration: releaseDuration
        ))
        self.stateBox = stateBox
        self.outputFormat = format

        // Captures `input`/`stateBox`/`sampleRate` directly, not `self` — all three captured
        // values are `Sendable` (`Oscillator` and `StateBox` are both `Mutex`-backed classes),
        // which is what this `@Sendable` render closure actually needs; `AmplitudeEnvelope`
        // holding a non-Sendable `AVAudioNode` never has to become `Sendable` itself as a result.
        let oscillator = input
        let sampleRate = format.sampleRate
        self.avAudioNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let raw = buffers[0].mData else { return noErr }
            let outBuffer = UnsafeMutableBufferPointer<Float>(
                start: raw.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            oscillator.fill(outBuffer, sampleRate: sampleRate)
            stateBox.mutex.withLock { s in
                for i in outBuffer.indices {
                    s.gain = Self.nextGain(
                        currentGain: s.gain,
                        phase: &s.phase,
                        attackDuration: s.attackDuration,
                        decayDuration: s.decayDuration,
                        sustainLevel: s.sustainLevel,
                        releaseDuration: s.releaseDuration,
                        sampleRate: sampleRate
                    )
                    outBuffer[i] *= s.gain
                }
            }
            return noErr
        }
    }

    /// A redundant `openGate()` while already open (the common case: the same pitch replaying
    /// back-to-back) is a no-op, same as feeding Soundpipe's ADSR filter an unchanged `1` input
    /// twice in a row never counts as a fresh rising edge — only a genuine closed-to-open
    /// transition starts a new attack.
    public func openGate() {
        stateBox.mutex.withLock { s in
            guard !s.gateOpen else { return }
            s.gateOpen = true
            s.phase = .attack
        }
    }

    public func closeGate() {
        stateBox.mutex.withLock { s in
            guard s.gateOpen else { return }
            s.gateOpen = false
            s.phase = .release
        }
    }

    /// One-pole exponential filter chasing whichever level the current phase targets — the same
    /// shape Soundpipe's `sp_adsr_compute` uses (`pole = exp(-1/(tau·sr))`), reimplemented as a
    /// plain phase-targets-a-level state machine instead of Soundpipe's specific per-sample
    /// bookkeeping. `phase` advances attack -> decay once `gain` settles near 1, and release -> idle
    /// once `gain` settles near 0 (an addition beyond Soundpipe's own behavior, which never
    /// explicitly parks in an idle state — silencing the output once fully released avoids running
    /// this filter forever on an asymptotically-tiny signal that never reaches exactly zero).
    static func nextGain(
        currentGain: Float,
        phase: inout EnvelopePhase,
        attackDuration: Float,
        decayDuration: Float,
        sustainLevel: Float,
        releaseDuration: Float,
        sampleRate: Double
    ) -> Float {
        let target: Float
        let tau: Float
        switch phase {
        case .idle:
            return 0
        case .attack:
            target = 1.0
            tau = attackDuration
        case .decay:
            target = sustainLevel
            tau = decayDuration
        case .release:
            target = 0.0
            tau = releaseDuration
        }

        let pole = Float(exp(-1.0 / (Double(max(tau, 0.0001)) * sampleRate)))
        let newGain = pole * currentGain + (1 - pole) * target

        if phase == .attack && newGain > 0.999 {
            phase = .decay
        } else if phase == .release && newGain < 0.0001 {
            phase = .idle
            return 0
        }
        return newGain
    }
}
