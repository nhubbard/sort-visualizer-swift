import Foundation
import ToneKitDSP

/// Turns a `SortToneEvent` into the `ToneCommand`s that produce it — the pitch/timing semantics
/// that used to live directly inside `AudioEngineKit.AudioService`, extracted so both the
/// standalone app and a future headless AU driver hear the identical mapping (AUDIO_UNIT_PLAN.md
/// §2). Stateful (tracks the last frequency it mapped) because the retrigger-on-pitch-change rule
/// below needs to compare against it — a fresh `ToneMapper` per voice, not a shared/static one.
public struct ToneMapper: Sendable {
  private var currentFrequency: Float = 0

  public init() {}

  /// A redundant `.setFrequency`/`.openGate` pair at the same pitch (the common case: the same
  /// bar replaying back-to-back) never re-closes the gate first — only a genuine pitch change
  /// does, so the envelope doesn't re-trigger its attack on every single event. Mirrors exactly
  /// what `AudioService.play` used to do inline: `if frequency != currentFrequency { closeGate()
  /// }` before setting the new frequency and opening the gate.
  public mutating func commands(for event: SortToneEvent, noteRange: ClosedRange<Int>) -> [ToneCommand] {
    let frequency = Self.frequency(forValue: event.value, in: event.range, noteRange: noteRange)
    var commands: [ToneCommand] = []
    if frequency != currentFrequency {
      commands.append(.closeGate)
    }
    currentFrequency = frequency
    commands.append(.setFrequency(Double(frequency)))
    commands.append(.openGate)
    return commands
  }

  /// Pure value→pitch mapping — moved verbatim from `AudioService.frequency(forValue:in:
  /// noteRange:)`. Linearly maps `value`'s position in `range` onto `noteRange` (MIDI note
  /// numbers), then converts to Hz via the standard equal-tempered formula.
  public static func frequency(
    forValue value: Int, in range: ClosedRange<Int>, noteRange: ClosedRange<Int>
  ) -> Float {
    let span = range.upperBound - range.lowerBound
    let ratio: Float = span > 0 ? Float(value - range.lowerBound) / Float(span) : 0.5
    let note =
      Float(noteRange.lowerBound) + ratio * Float(noteRange.upperBound - noteRange.lowerBound)
    return 440.0 * pow(2.0, (note - 69.0) / 12.0)
  }
}
