import AVFoundation
import CoreAudio
import ToneKitDSP

/// Replaces what `AmplitudeEnvelope` was for callers in today's combined `ToneKit`: a `Node` +
/// `Gated` conformance the standalone app's `AudioEngineKit.AudioService` attaches to an
/// `AudioEngine`'s output and drives via `frequency`/`openGate()`/`closeGate()` — except the
/// actual DSP now lives in a `ToneRenderer` (from `ToneKitDSP`) this class only wires into an
/// `AVAudioSourceNode`'s render closure, rather than doing envelope math and locking inline itself
/// the way `AmplitudeEnvelope` did. See `AUDIO_UNIT_PLAN.md` §3.
public final class ToneVoice: Node, Gated {
  private let renderer: ToneRenderer
  public let avAudioNode: AVAudioNode
  public let outputFormat: AVAudioFormat

  /// `maxFrameCount` defaults to a conservative fixed upper bound comfortably above typical
  /// CoreAudio buffer sizes for the standalone app's `AVAudioEngine` graph. The AU extension
  /// targets (later phases) instead prepare their own `ToneRenderer` with the host's real
  /// `maximumFramesToRender` — the more precise source of truth `AUDIO_UNIT_PLAN.md` §5 calls for
  /// — so this default only ever applies to the standalone app's voice.
  public init(
    oscillator: OscillatorDSP,
    envelope: EnvelopeDSP,
    maxFrameCount: Int = 4096,
    format: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
  ) {
    let renderer = ToneRenderer(oscillator: oscillator, envelope: envelope)
    renderer.prepare(maxFrameCount: maxFrameCount)
    self.renderer = renderer
    self.outputFormat = format
    self.frequency = oscillator.frequency

    // Captures `renderer` directly, not `self` — `renderer` is already `@unchecked Sendable` and
    // owns everything this closure touches, so `ToneVoice` (which holds a non-Sendable
    // `AVAudioNode`) never needs to become `Sendable` itself as a result. Mirrors the same care
    // today's `AmplitudeEnvelope.init` already takes.
    self.avAudioNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
      let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
      guard let raw = buffers[0].mData else { return noErr }
      let outBuffer = UnsafeMutableBufferPointer<Float>(
        start: raw.assumingMemoryBound(to: Float.self),
        count: Int(frameCount)
      )
      renderer.render(into: outBuffer, sampleRate: format.sampleRate)
      return noErr
    }
  }

  /// Assignment mirrors today's `osc.frequency = frequency` call site exactly — `AudioService`'s
  /// `play(value:in:holdSeconds:)` doesn't need to change beyond the type it's written against.
  public var frequency: Float {
    didSet { renderer.enqueue(.setFrequency(Double(frequency))) }
  }

  public func openGate() {
    renderer.enqueue(.openGate)
  }

  public func closeGate() {
    renderer.enqueue(.closeGate)
  }
}
