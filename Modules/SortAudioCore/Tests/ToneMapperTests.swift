import Foundation
import Testing
import ToneKitDSP

@testable import SortAudioCore

@Suite
struct ToneMapperTests {
  @Test(arguments: [
    (value: 1, range: 1...100, noteRange: 36...72, expectedNote: 36),
    (value: 100, range: 1...100, noteRange: 36...72, expectedNote: 72),
    (value: 50, range: 0...100, noteRange: 36...96, expectedNote: 66)
  ])
  func frequencyMapsValueLinearlyOntoNoteRangeThenConvertsToHz(
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

  @Test
  func repeatingTheSamePitchNeverRetriggersTheGate() {
    var mapper = ToneMapper()
    let event = SortToneEvent(value: 50, range: 1...100, holdSeconds: 0.1)

    let first = mapper.commands(for: event, noteRange: 36...72)
    let second = mapper.commands(for: event, noteRange: 36...72)

    // The very first mapping always closes (there's no prior pitch to match), but a repeat of
    // the same value/range/noteRange must not close the gate again before reopening it.
    #expect(first == [.closeGate, .setFrequency(first.frequencyPayload!), .openGate])
    #expect(second == [.setFrequency(first.frequencyPayload!), .openGate])
  }

  @Test
  func aDifferentPitchClosesTheGateBeforeReopening() {
    var mapper = ToneMapper()
    let low = SortToneEvent(value: 1, range: 1...100, holdSeconds: 0.1)
    let high = SortToneEvent(value: 100, range: 1...100, holdSeconds: 0.1)

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
