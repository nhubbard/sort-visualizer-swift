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
    commands.append(.setAccent(Self.accent(for: event.operationKind)))
    commands.append(.setPan(Self.pan(forIndex: event.index, arraySize: event.arraySize)))
    commands.append(.setFrequency(Double(frequency)))
    commands.append(.openGate)
    return commands
  }

  /// Maps an event's position in the array onto `[-1, 1]` so you hear a sort's spatial progress —
  /// left-to-right across the array reads as left-to-right in the stereo field. A single-element
  /// array (or any degenerate `arraySize <= 1`) centers rather than dividing by zero.
  private static func pan(forIndex index: Int, arraySize: Int) -> Float {
    guard arraySize > 1 else { return 0 }
    return 2 * Float(index) / Float(arraySize - 1) - 1
  }

  /// Swaps (the actual element movement) read as louder/more present than compares or value-writes
  /// (bookkeeping) — the compare/swap sonic distinction this type exists to provide, kept as a
  /// separate multiplicative layer from the AU remote's own Gain slider (`ToneCommand.setAccent`'s
  /// own doc comment explains why).
  private static func accent(for operationKind: SortOperationKind) -> Float {
    operationKind == .swap ? 1.0 : 0.65
  }

  /// Pure value→pitch mapping — originally moved verbatim from `AudioService.frequency(forValue:
  /// in:noteRange:)`, since extended with scale quantization. Linearly maps `value`'s position in
  /// `range` onto `noteRange` (MIDI note numbers), snaps that to the nearest pentatonic-minor scale
  /// degree (relative to `noteRange.lowerBound` as the root), then converts to Hz via the standard
  /// equal-tempered formula. Quantizing is what turns "any value in range maps to some frequency"
  /// into "sounds like music" — a raw continuous sweep across essentially-arbitrary sort values
  /// produces essentially-arbitrary intervals.
  public static func frequency(
    forValue value: Int, in range: ClosedRange<Int>, noteRange: ClosedRange<Int>
  ) -> Float {
    let span = range.upperBound - range.lowerBound
    let ratio: Float = span > 0 ? Float(value - range.lowerBound) / Float(span) : 0.5
    let note =
      Float(noteRange.lowerBound) + ratio * Float(noteRange.upperBound - noteRange.lowerBound)
    let quantizedNote = quantized(note, root: noteRange.lowerBound)
    return 440.0 * pow(2.0, (quantizedNote - 69.0) / 12.0)
  }

  /// Pentatonic minor, as semitone offsets from whatever root a caller supplies — the classic
  /// choice for algorithmically-generated pitch sequences: every degree sounds consonant against
  /// every other, so there's no "wrong note" an arbitrary sequence of sort values could land on.
  /// Deliberately hardcoded rather than a user-facing setting for now — `SettingsKit` can't depend
  /// on this module today (no `SortAudioCore`/`ToneKitDSP` edge in `Project.swift`), and a single
  /// well-chosen default already fixes the "sounds random" problem this exists to solve.
  private static let scaleSemitones = [0, 3, 5, 7, 10]

  /// Snaps a continuous MIDI note number to the nearest `scaleSemitones` degree in whichever
  /// octave it already falls in, relative to `root`. Known simplification: the nearest-degree
  /// search doesn't look across the octave boundary, so a note very close to the top of its octave
  /// might not be the *globally* nearest scale degree (the equivalent degree one octave up could be
  /// closer) — cosmetic, not a correctness issue, and not worth the extra complexity here.
  private static func quantized(_ note: Float, root: Int) -> Float {
    let offset = note - Float(root)
    let octave = (offset / 12).rounded(.down)
    let semitoneInOctave = offset - octave * 12
    let nearestDegree = scaleSemitones.min {
      abs(Float($0) - semitoneInOctave) < abs(Float($1) - semitoneInOctave)
    }!
    return Float(root) + octave * 12 + Float(nearestDegree)
  }
}
