/// Which kind of sort operation produced a `SortToneEvent` — lets `ToneMapper` (and, downstream,
/// the AU-hosted remote's Tone panel) give compares and swaps genuinely different sonic treatment
/// instead of playing identically, which they did before this type existed:
/// `SortSession.makeOnStepClosure` used to combine `.compare`/`.swap` into a single switch-case arm
/// with no way to tell them apart.
///
/// `UInt8`-backed so the wire encoding (`SortAudioBridgeKit`'s `BridgeWireCodec`) is a single byte,
/// matching `RemoteControlCommand`'s existing convention.
public enum SortOperationKind: UInt8, Sendable, Equatable, CaseIterable {
  case compare
  case swap
  case setValue
}
