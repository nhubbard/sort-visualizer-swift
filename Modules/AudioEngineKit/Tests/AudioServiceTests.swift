import Foundation
import Testing
@testable import AudioEngineKit

@Suite
struct AudioServiceTests {
    @Test(arguments: [
        (value: 1, range: 1...100, noteRange: 36...72, expectedNote: 36),
        (value: 100, range: 1...100, noteRange: 36...72, expectedNote: 72),
        (value: 50, range: 0...100, noteRange: 36...96, expectedNote: 66),
    ])
    func frequencyMapsValueLinearlyOntoNoteRangeThenConvertsToHz(
        value: Int,
        range: ClosedRange<Int>,
        noteRange: ClosedRange<Int>,
        expectedNote: Int
    ) {
        let expected = 440.0 * pow(2.0, (Float(expectedNote) - 69.0) / 12.0)
        let actual = AudioService.frequency(forValue: value, in: range, noteRange: noteRange)
        #expect(abs(actual - expected) < 0.01)
    }

    @Test
    func frequencyDoesNotCrashOnADegenerateSingleValueRange() {
        let frequency = AudioService.frequency(forValue: 5, in: 5...5, noteRange: 36...72)
        #expect(frequency > 0)
    }

    // No test constructs a live `AudioService()` here: doing so builds a real AudioKit DSP graph
    // (Oscillator -> AmplitudeEnvelope -> Fader -> AudioEngine), and instantiating that outside a
    // running app with a real audio session crashes at AudioKit's native layer ("parameter map
    // not initialized") — a bare test host, not a bug in this code. `frequency(forValue:in:
    // noteRange:)` above covers the actual logic; `AudioService`'s wiring is verified by actually
    // running the app (this phase's checkpoint) rather than by a unit test exercising live audio.
}
