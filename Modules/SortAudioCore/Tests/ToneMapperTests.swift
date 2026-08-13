import Foundation
import Testing
import ToneKitDSP

@testable import SortAudioCore

@Suite
struct ToneMapperTests {
  /// Expected notes are the *quantized* result, not the raw linear interpolation — value 50 in
  /// `0...100` onto `36...96` linearly lands on MIDI note 66, but 66 sits exactly between the
  /// pentatonic-minor scale's 5th and 7th degrees above root 36 (65 and 67), a tie `quantized(_:
  /// root:)` breaks toward whichever degree appears first in its table (5, giving note 65) — see
  /// that function's own doc comment on this known, accepted simplification.
  @Test(arguments: [
    (value: 1, range: 1...100, noteRange: 36...72, expectedNote: 36),
    (value: 100, range: 1...100, noteRange: 36...72, expectedNote: 72),
    (value: 50, range: 0...100, noteRange: 36...96, expectedNote: 65)
  ])
  func frequencyMapsValueOntoNoteRangeThenQuantizesToScaleThenConvertsToHz(
    value: Int,
    range: ClosedRange<Int>,
    noteRange: ClosedRange<Int>,
    expectedNote: Int
  ) {
    let expected = 440.0 * pow(2.0, (Float(expectedNote) - 69.0) / 12.0)
    let actual = ToneMapper.frequency(forValue: value, in: range, noteRange: noteRange)
    #expect(abs(actual - expected) < 0.01)
  }

  @Test
  func frequencyDoesNotCrashOnADegenerateSingleValueRange() {
    let frequency = ToneMapper.frequency(forValue: 5, in: 5...5, noteRange: 36...72)
    #expect(frequency > 0)
  }

  /// Confirms the actual point of quantization: across a wide sweep of arbitrary values, every
  /// resulting pitch lands on a pentatonic-minor degree relative to the note range's root — never
  /// an "in-between" note the old continuous mapping could produce.
  @Test
  func frequencyOnlyEverProducesPentatonicMinorScaleDegrees() {
    let noteRange = 36...96
    let root = Float(noteRange.lowerBound)
    let scaleSemitones: Set<Int> = [0, 3, 5, 7, 10]

    for value in 0...200 {
      let frequency = ToneMapper.frequency(forValue: value, in: 0...200, noteRange: noteRange)
      let note = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
      let semitoneFromRoot = Int((Float(note) - root).rounded())
      let semitoneInOctave = ((semitoneFromRoot % 12) + 12) % 12
      #expect(
        scaleSemitones.contains(semitoneInOctave),
        "value \(value) produced a note \(semitoneInOctave) semitones into its octave, not on the pentatonic minor scale \(scaleSemitones)"
      )
    }
  }

  /// A custom note range configured low enough to reach the floor (MIDI note 24, ~32.7 Hz) must
  /// never produce a note below it — below that, a note gated for a typical `holdSeconds` doesn't
  /// even complete a full waveform cycle, reading as a click rather than a tone. Clamped on the
  /// note-range floor before quantization, so results still land on a real pentatonic-minor
  /// degree instead of an arbitrary post-hoc-clamped Hz value.
  @Test
  func frequencyNeverGoesBelowTheMinimumNoteFloor() {
    let floorHz: Float = 440.0 * pow(2.0, (24.0 - 69.0) / 12.0)
    for value in 0...10 {
      let frequency = ToneMapper.frequency(forValue: value, in: 0...10, noteRange: 0...12)
      #expect(
        frequency >= floorHz - 0.01,
        "value \(value) produced \(frequency) Hz, below the floor of \(floorHz) Hz")
    }
  }

  @Test
  func repeatingTheSamePitchNeverRetriggersTheGate() {
    var mapper = ToneMapper()
    let event = SortToneEvent(
      value: 50, range: 1...100, holdSeconds: 0.1, index: 0, arraySize: 100, operationKind: .compare)

    let first = mapper.commands(for: event, noteRange: 36...72)
    let second = mapper.commands(for: event, noteRange: 36...72)

    // The very first mapping always closes (there's no prior pitch to match), but a repeat of
    // the same value/range/noteRange must not close the gate again before reopening it.
    #expect(
      first
        == [
          .closeGate, .setAccent(0.65), .setPan(-1.0), .setFrequency(first.frequencyPayload!),
          .openGate,
        ])
    #expect(
      second
        == [.setAccent(0.65), .setPan(-1.0), .setFrequency(first.frequencyPayload!), .openGate])
  }

  @Test
  func aDifferentPitchClosesTheGateBeforeReopening() {
    var mapper = ToneMapper()
    let low = SortToneEvent(
      value: 1, range: 1...100, holdSeconds: 0.1, index: 0, arraySize: 100, operationKind: .compare)
    let high = SortToneEvent(
      value: 100, range: 1...100, holdSeconds: 0.1, index: 0, arraySize: 100,
      operationKind: .compare)

    _ = mapper.commands(for: low, noteRange: 36...72)
    let commands = mapper.commands(for: high, noteRange: 36...72)

    #expect(commands.first == .closeGate)
    #expect(commands.last == .openGate)
  }
}

extension Array where Element == ToneCommand {
  /// Pulls the `Double` payload out of whichever `.setFrequency` command is in this array, for
  /// tests that need to assert against "whatever frequency was actually computed" rather than
  /// recomputing the exact value themselves.
  fileprivate var frequencyPayload: Double? {
    for command in self {
      if case .setFrequency(let hz) = command { return hz }
    }
    return nil
  }
}
