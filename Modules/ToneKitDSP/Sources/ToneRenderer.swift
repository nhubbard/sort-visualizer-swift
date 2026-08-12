/// The single owner of one voice's DSP state — one `OscillatorDSP`, one `EnvelopeDSP`, one
/// `ToneCommandQueue` — and the one entry point every host adapter (`ToneKitAVFoundation`'s
/// `AVAudioSourceNode` closure today; an `AUAudioUnit.internalRenderBlock` and, later, a VST3
/// `process()` callback) calls to actually produce audio. See `AUDIO_UNIT_PLAN.md` §3/§5.
///
/// `render(into:sampleRate:)` must only ever be called from one thread at a time — the realtime
/// render thread — and must never be called concurrently with itself. `enqueue(_:)` is the only
/// method safe to call from any other thread. `prepare(maxFrameCount:)` must complete before the
/// first `render` call and must not be called concurrently with `render`.
///
/// `@unchecked Sendable` for the same reason as `ToneCommandQueue`: safety here comes from the
/// single-owner/single-caller discipline documented above, not from anything the type system
/// checks. `OscillatorDSP`/`EnvelopeDSP` are plain, lock-free value types mutated only from within
/// `render`, so there is no synchronization to perform on them at all — only `ToneCommandQueue`
/// (itself already `@unchecked Sendable`) crosses the realtime boundary.
public final class ToneRenderer: @unchecked Sendable {
  private var oscillator: OscillatorDSP
  private var envelope: EnvelopeDSP
  private let commands: ToneCommandQueue

  public init(
    oscillator: OscillatorDSP,
    envelope: EnvelopeDSP,
    commandQueue: ToneCommandQueue = ToneCommandQueue()
  ) {
    self.oscillator = oscillator
    self.envelope = envelope
    self.commands = commandQueue
  }

  /// Allocates render scratch storage up front. Must run before the first `render` call, from any
  /// thread other than a concurrent `render` call itself.
  public func prepare(maxFrameCount: Int) {
    oscillator.prepare(maxFrameCount: maxFrameCount)
  }

  /// Producer-side entry point — safe to call from any thread except the realtime render thread's
  /// own callback. Returns `false` if the underlying queue is full and the command was dropped.
  @discardableResult
  public func enqueue(_ command: ToneCommand) -> Bool {
    commands.push(command)
  }

  /// Realtime render thread only. Drains every command due since the last call, then renders one
  /// buffer's worth of audio — the same two-step combination (`fill` a raw tone, then multiply in
  /// the envelope's gain) today's `AmplitudeEnvelope`'s `AVAudioSourceNode` closure performs, just
  /// no longer behind two separately-locked mutexes.
  public func render(into buffer: UnsafeMutableBufferPointer<Float>, sampleRate: Double) {
    drainDueCommands()
    oscillator.fill(buffer, sampleRate: sampleRate)
    envelope.applyGain(to: buffer, sampleRate: sampleRate)
  }

  private func drainDueCommands() {
    while let command = commands.pop() {
      switch command {
      case .setFrequency(let hz):
        oscillator.frequency = Float(hz)
      case .openGate:
        envelope.openGate()
      case .closeGate:
        envelope.closeGate()
      case .setAttackDuration(let seconds):
        envelope.attackDuration = seconds
      case .setDecayDuration(let seconds):
        envelope.decayDuration = seconds
      case .setSustainLevel(let level):
        envelope.sustainLevel = level
      case .setReleaseDuration(let seconds):
        envelope.releaseDuration = seconds
      case .setDetuningOffset(let hz):
        oscillator.detuningOffset = hz
      case .setAmplitude(let amplitude):
        oscillator.amplitude = amplitude
      case .setAccent(let accent):
        envelope.accent = accent
      }
    }
  }
}
