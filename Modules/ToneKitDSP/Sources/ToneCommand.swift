/// The transport-neutral unit of control between the non-realtime side (today: `ToneKitAVFoundation`
/// standalone-app wiring; later: `SortAudioCore`'s `LocalToneEventSink`) and `ToneRenderer`'s
/// realtime render path — see `AUDIO_UNIT_PLAN.md` §4/§6. Deliberately independent of AVFoundation,
/// AudioUnit, or any host SDK type.
///
/// No sample-accurate offset field yet: commands apply at the start of whichever `render(...)` call
/// drains them. `AUDIO_UNIT_PLAN.md` §6 leaves mid-buffer offsets as something to add only if real
/// render-block-size testing (Phase 3+) shows block-boundary granularity is audibly insufficient —
/// adding it later means widening this enum, not restructuring anything that consumes it.
public enum ToneCommand: Sendable, Equatable {
  case setFrequency(Double)
  case openGate
  case closeGate
  // Below: the AU-hosted remote's audio-production parameters (`AUDIO_UNIT_PLAN.md` §7's "Plug-in
  // UI") — a host's `AUParameter` observer enqueues these exactly like `SortAudioCore` enqueues
  // `setFrequency`/gate commands, so they drain on the render thread through the same mechanism.
  case setAttackDuration(Float)
  case setDecayDuration(Float)
  case setSustainLevel(Float)
  case setReleaseDuration(Float)
  case setDetuningOffset(Float)
  case setAmplitude(Float)
}
