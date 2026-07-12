import Testing
@testable import AudioEngineKit

@MainActor
@Suite
struct NoOpAudioServiceTests {
    @Test
    func conformsAndNeverThrowsOrCrashes() throws {
        let service: any AudioPlaying = NoOpAudioService()
        try service.start()
        service.play(value: 5, in: 0...10, holdSeconds: 0.05)
        service.stop()
    }
}
