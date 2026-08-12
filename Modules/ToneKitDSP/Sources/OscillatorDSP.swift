// This file's public API (`frequency`/`amplitude`/`detuningOffset`/`detuningMultiplier`) is
// modeled on SoundpipeAudioKit's `Oscillator`, reduced to a plain sine wave (no waveform table
// selection) and reimplemented as a direct phase accumulator instead of a wrapped Soundpipe
// "oscl" Audio Unit. See NOTICE.md.
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

/// A single sine voice's DSP state, owned exclusively by whichever `ToneRenderer` holds it — a
/// plain value type rather than today's `ToneKit.Oscillator`'s `Mutex`-guarded class, because
/// there's exactly one mutable reference to it once wired into a `ToneRenderer` (see
/// `AUDIO_UNIT_PLAN.md` §5): frequency/amplitude changes cross from the control side to the render
/// thread as `ToneCommand`s through `ToneRenderer`'s queue, not by another thread poking this
/// struct's properties directly, so no internal synchronization is needed here at all.
public struct OscillatorDSP: Sendable {
  public var frequency: Float
  public var amplitude: Float
  public var detuningOffset: Float
  public var detuningMultiplier: Float
  private var phase: Double = 0

  // Preallocated once by `prepare(maxFrameCount:)` rather than lazily resized inside `fill` —
  // today's `ToneKit.Oscillator` resizes these on first use/whenever the buffer size changes,
  // which is a render-thread allocation `AUDIO_UNIT_PLAN.md` §5 requires eliminating for the AU
  // render path. `fill` renders into a prefix of these sized to the actual call's frame count.
  private var scratchPhases: [Double] = []
  private var scratchSines: [Double] = []

  public init(
    frequency: Float = 440.0,
    amplitude: Float = 1.0,
    detuningOffset: Float = 0.0,
    detuningMultiplier: Float = 1.0
  ) {
    self.frequency = frequency
    self.amplitude = amplitude
    self.detuningOffset = detuningOffset
    self.detuningMultiplier = detuningMultiplier
  }

  /// Allocates render scratch storage up front, sized to the largest frame count `fill` will ever
  /// be asked to render in one call. Must be called before the first `fill(_:sampleRate:)` call,
  /// from any thread — never from the realtime render thread itself, since this is the one place
  /// allocation is allowed.
  public mutating func prepare(maxFrameCount: Int) {
    scratchPhases = [Double](repeating: 0, count: maxFrameCount)
    scratchSines = [Double](repeating: 0, count: maxFrameCount)
  }

  /// One computation pass per render buffer (typically a few hundred frames), not per sample —
  /// negligible cost regardless of buffer size.
  ///
  /// Vectorized via Accelerate rather than a per-sample loop: phase can run unwrapped across the
  /// whole buffer and get wrapped back into `0..<2π` once at the end, since `sin` is exactly
  /// periodic — one `vDSP`/`vForce` call each instead of a branch-per-sample scalar loop.
  ///
  /// `buffer.count` must not exceed the `maxFrameCount` passed to `prepare` — rather than resize
  /// (an allocation on what may be the realtime render thread), a call past that capacity renders
  /// silence into the excess and clamps to the prepared capacity, since that's a `prepare`-time
  /// misconfiguration bug to fix, not a condition to allocate through on the render thread.
  public mutating func fill(_ buffer: UnsafeMutableBufferPointer<Float>, sampleRate: Double) {
    let count = min(buffer.count, scratchPhases.count)
    guard let output = buffer.baseAddress, buffer.count > 0 else { return }
    if count < buffer.count {
      // Not prepared for a buffer this large (or not prepared at all) — silence rather than
      // whatever was previously in the caller's buffer, and never allocate here to catch up.
      output.advanced(by: count).update(repeating: 0, count: buffer.count - count)
    }
    guard count > 0 else { return }

    let effectiveFrequency =
      Double(frequency) * Double(detuningMultiplier) + Double(detuningOffset)
    let increment = Self.phaseIncrement(frequency: effectiveFrequency, sampleRate: sampleRate)

    // phases[i] = phase + i * increment
    var start = phase
    var step = increment
    scratchPhases.withUnsafeMutableBufferPointer { phases in
      vDSP_vrampD(&start, &step, phases.baseAddress!, 1, vDSP_Length(count))
    }

    // sines[i] = sin(phases[i])
    var n = Int32(count)
    scratchSines.withUnsafeMutableBufferPointer { sines in
      scratchPhases.withUnsafeMutableBufferPointer { phases in
        vvsin(sines.baseAddress!, phases.baseAddress!, &n)
      }
    }

    // sines[i] *= amplitude, then narrowed straight into the Float output buffer.
    var amplitudeValue = Double(amplitude)
    scratchSines.withUnsafeMutableBufferPointer { sines in
      vDSP_vsmulD(sines.baseAddress!, 1, &amplitudeValue, sines.baseAddress!, 1, vDSP_Length(count))
      vDSP_vdpsp(sines.baseAddress!, 1, output, 1, vDSP_Length(count))
    }

    phase = Self.wrappedPhase(start: phase, increment: increment, count: count)
  }

  /// Pure sine-generation step — the scalar reference this file's `OscillatorDSPTests` pin the
  /// math against, and what `fill` used to call directly per-sample before being vectorized above.
  /// Not dead code: every test in this file exercises the algorithm through these two functions
  /// specifically because they don't need a real realtime render context, matching
  /// `AudioService.frequency(forValue:in:noteRange:)`'s own "pure math, no live engine" split.
  public static func phaseIncrement(frequency: Double, sampleRate: Double) -> Double {
    2 * Double.pi * frequency / sampleRate
  }

  public static func nextSample(phase: Double, phaseIncrement: Double) -> (
    sample: Float, nextPhase: Double
  ) {
    let sample = Float(sin(phase))
    var nextPhase = phase + phaseIncrement
    if nextPhase >= 2 * Double.pi { nextPhase -= 2 * Double.pi }
    return (sample, nextPhase)
  }

  /// Where `fill`'s per-sample wrap-if-past-2π check moved to: since nothing between here and the
  /// next `fill` call ever reads an intermediate phase, wrapping once at the very end of the
  /// buffer is equivalent to wrapping after every sample, and cheaper.
  public static func wrappedPhase(start: Double, increment: Double, count: Int) -> Double {
    let twoPi = 2 * Double.pi
    let wrapped = (start + Double(count) * increment).truncatingRemainder(dividingBy: twoPi)
    return wrapped < 0 ? wrapped + twoPi : wrapped
  }
}
