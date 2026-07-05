import Testing
@testable import AudioEngineKit

@Suite
struct NoOpAudioServiceTests {
    @Test
    func conformsAndNeverThrowsOrCrashes() throws {
        let service: any AudioPlaying = NoOpAudioService()
        try service.start()
        service.play(value: 5, in: 0...10)
        service.stop()
    }
}
