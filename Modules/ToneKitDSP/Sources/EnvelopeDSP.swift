// This file's public API (`EnvelopePhase`, the ADSR parameters) is modeled on AudioKitEX's
// `Gated` protocol and SoundpipeAudioKit's `AmplitudeEnvelope`. The envelope *shape* — a one-pole
// exponential filter chasing a target level, rather than a linear ramp — mirrors Soundpipe's
// `adsr.c` (`pole = exp(-1 / (tau * sampleRate))`) without copying its per-sample state machine
// (attack-time fudge factor, manual timer counting, no explicit idle exit). See NOTICE.md.
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

public enum EnvelopePhase: Sendable, Equatable {
  case idle, attack, decay, release
}

/// Triggerable attack/decay/sustain/release envelope state, applied to whatever an owning
/// `ToneRenderer` fills into a buffer. Unlike today's `ToneKit.AmplitudeEnvelope`, this owns no
/// `AVAudioNode` and no `Mutex` — it's a plain value type mutated only by the render thread that
/// owns it, with gate open/close arriving as `ToneCommand`s rather than direct property writes
/// from another thread (see Documentation/docs/architecture/audio.md).
public struct EnvelopeDSP: Sendable {
  public private(set) var phase: EnvelopePhase = .idle
  private var gateOpen = false
  private var gain: Float = 0
  public var attackDuration: Float
  public var decayDuration: Float
  public var sustainLevel: Float
  public var releaseDuration: Float
  /// A multiplicative gain layer, deliberately separate from the AU-hosted remote's user-facing
  /// Gain slider (Documentation/docs/architecture/audio.md) — `SortAudioCore.ToneMapper` drives this per-operation
  /// (louder for swaps, softer for compares/value-writes) without ever fighting a performer's own
  /// manual dial-in, since the two multiply together instead of one clobbering the other. This is
  /// the *target* `applyGain` ramps `appliedAccent` toward, not applied directly — see that
  /// property's doc comment.
  public var accent: Float = 1.0
  /// The accent value actually multiplied into samples, linearly ramped toward `accent` across
  /// each `applyGain` call rather than snapping to it instantly. `accent` changes on nearly every
  /// note (`SortAudioCore.ToneMapper` sets it per operation), so applying it as a flat per-buffer
  /// scalar was a real, reported source of audible clicking — the same class of bug
  /// `OscillatorDSP`'s ramped pan/amplitude scale fixes, for the same reason.
  private var appliedAccent: Float = 1.0

  public init(
    attackDuration: Float = 0.1,
    decayDuration: Float = 0.1,
    sustainLevel: Float = 1.0,
    releaseDuration: Float = 0.1,
    accent: Float = 1.0
  ) {
    self.attackDuration = attackDuration
    self.decayDuration = decayDuration
    self.sustainLevel = sustainLevel
    self.releaseDuration = releaseDuration
    self.accent = accent
    self.appliedAccent = accent
  }

  /// A redundant `openGate()` while already open (the common case: the same pitch replaying
  /// back-to-back) is a no-op, same as feeding Soundpipe's ADSR filter an unchanged `1` input
  /// twice in a row never counts as a fresh rising edge — only a genuine closed-to-open
  /// transition starts a new attack.
  public mutating func openGate() {
    guard !gateOpen else { return }
    gateOpen = true
    phase = .attack
  }

  public mutating func closeGate() {
    guard gateOpen else { return }
    gateOpen = false
    phase = .release
  }

  /// Per-sample gain application over a whole render buffer — the same loop today's
  /// `AmplitudeEnvelope`'s `AVAudioSourceNode` render closure runs, just no longer inside a
  /// `Mutex.withLock`. Called after the oscillator has already filled `left`/`right` with raw
  /// samples. The envelope's temporal shape doesn't depend on pan — both channels are the same
  /// underlying tone, just at different equal-power gains — so one shared per-sample gain value
  /// applies identically to both.
  public mutating func applyGain(
    left: UnsafeMutableBufferPointer<Float>, right: UnsafeMutableBufferPointer<Float>,
    sampleRate: Double
  ) {
    let count = min(left.count, right.count)
    // Ramps `appliedAccent` toward `accent` linearly across this buffer — when they're already
    // equal (the common case: `accent` didn't change since the last buffer), `step` is 0 and this
    // degenerates to the flat multiply it always was.
    let step = count > 1 ? (accent - appliedAccent) / Float(count - 1) : 0
    for index in 0..<count {
      gain = Self.nextGain(
        currentGain: gain,
        phase: &phase,
        attackDuration: attackDuration,
        decayDuration: decayDuration,
        sustainLevel: sustainLevel,
        releaseDuration: releaseDuration,
        sampleRate: sampleRate
      )
      let scaled = gain * appliedAccent
      left[index] *= scaled
      right[index] *= scaled
      appliedAccent += step
    }
    appliedAccent = accent
  }

  /// One-pole exponential filter chasing whichever level the current phase targets — the same
  /// shape Soundpipe's `sp_adsr_compute` uses (`pole = exp(-1/(tau·sr))`), reimplemented as a
  /// plain phase-targets-a-level state machine instead of Soundpipe's specific per-sample
  /// bookkeeping. `phase` advances attack -> decay once `gain` settles near 1, and release -> idle
  /// once `gain` settles near 0 (an addition beyond Soundpipe's own behavior, which never
  /// explicitly parks in an idle state — silencing the output once fully released avoids running
  /// this filter forever on an asymptotically-tiny signal that never reaches exactly zero).
  public static func nextGain(
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
