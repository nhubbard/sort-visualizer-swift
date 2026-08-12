import AVFoundation
import CoreAudio
import ToneKitDSP

/// Adapts an already-built `ToneRenderer` (from `ToneKitDSP`) into an `AVAudioNode` this module's
/// `AudioEngine` can attach — nothing more. Earlier drafts of this type also exposed `frequency`/
/// `openGate()`/`closeGate()` (a `Gated` conformance) as the standalone app's way to talk to the
/// renderer directly; that's now `SortAudioCore.LocalToneEventSink`'s job instead (AUDIO_UNIT_PLAN.md
/// §4/Phase 2) — a `LocalToneEventSink` wraps the *same* `ToneRenderer` a caller hands to this type,
/// so `ToneVoice` only ever needs to know how to turn `ToneRenderer.render(...)` into audio, not how
/// to drive it.
public final class ToneVoice: Node {
  public let avAudioNode: AVAudioNode
  public let outputFormat: AVAudioFormat

  /// `maxFrameCount` defaults to a conservative fixed upper bound comfortably above typical
  /// CoreAudio buffer sizes for the standalone app's `AVAudioEngine` graph. The AU extension
  /// targets (later phases) instead prepare their own `ToneRenderer` with the host's real
  /// `maximumFramesToRender` — the more precise source of truth `AUDIO_UNIT_PLAN.md` §5 calls for
  /// — so this default only ever applies to the standalone app's voice. `renderer` is expected to
  /// already be freshly constructed (not yet `prepare`d) by the caller, since it's this
  /// initializer that calls `prepare(maxFrameCount:)`.
  public init(
    renderer: ToneRenderer,
    maxFrameCount: Int = 4096,
    format: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
  ) {
    renderer.prepare(maxFrameCount: maxFrameCount)
    self.outputFormat = format

    // Captures `renderer` directly, not `self` — `renderer` is already `@unchecked Sendable` and
    // owns everything this closure touches, so `ToneVoice` (which holds a non-Sendable
    // `AVAudioNode`) never needs to become `Sendable` itself as a result.
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
}
