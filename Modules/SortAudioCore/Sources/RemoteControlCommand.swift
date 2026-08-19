/// A transport-neutral remote-control command, the reverse-direction counterpart to
/// `SortToneEvent`: instead of audio events flowing app → AU extension, these flow AU extension →
/// app, letting a minimal AU-hosted remote (see Documentation/docs/architecture/audio.md's "The plug-in UI") drive the
/// standalone app's running sort without exposing any sort visualization, algorithm detail, or code
/// — only the same transport actions already available from the app's own run-control bar and menu
/// commands (`RunControlBar.swift`, `App/Sources/SortCommands.swift`).
///
/// `UInt8`-backed so the wire encoding (`SortAudioBridgeKit`'s `BridgeWireCodec`) is a single byte.
public enum RemoteControlCommand: UInt8, Sendable, CaseIterable {
  case togglePlayback
  case restart
  case regenerate
  case stepForward
  case stepBackward
  case toggleSound
}
