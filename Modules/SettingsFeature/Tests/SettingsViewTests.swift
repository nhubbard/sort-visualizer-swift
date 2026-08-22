import Testing

@testable import SettingsFeature

@Suite
struct SettingsViewTests {
  @Test
  func fixedDurationPacingShowsTheTargetDurationDirectly() {
    let text = recordingCapEstimateText(
      useFixedDurationPacing: true, targetPlaybackDuration: 30, recordingOperationCap: 300_000,
      playbackSpeed: 30)
    #expect(text == "≈ 30s per run at the fixed-duration target")
  }

  @Test
  func rateBasedPacingShowsTheComputedMinutesEstimate() {
    let text = recordingCapEstimateText(
      useFixedDurationPacing: false, targetPlaybackDuration: 10, recordingOperationCap: 300_000,
      playbackSpeed: 30)
    // 300_000 / 30 / 60 == 166.67 minutes.
    #expect(text == "≈ 166.7 min at the current playback speed")
  }
}
