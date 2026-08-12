import AudioToolbox
import AVFoundation
import Testing

@testable import SortAudioUnitKit

/// Builds a `FourCharCode` (`OSType`) from a 4-character string — the same encoding
/// `AudioComponentDescription`'s type/subtype/manufacturer fields use, matching the literal
/// 4-character strings the extension's own Info.plist `AudioComponents` entry declares.
extension FourCharCode {
  fileprivate init(_ string: String) {
    var code: FourCharCode = 0
    for byte in string.utf8 { code = (code << 8) | FourCharCode(byte) }
    self = code
  }
}

@Suite
struct SortAudioUnitTests {
  /// Matches the extension's real Info.plist `AudioComponents` entry — not that it needs to match
  /// anything registered for this test, since constructing `SortAudioUnit` directly bypasses the
  /// whole AudioComponent registration/lookup system entirely (exactly what a fast, host-
  /// independent unit test wants).
  private static let componentDescription = AudioComponentDescription(
    componentType: kAudioUnitType_MusicDevice,
    componentSubType: FourCharCode("SrtS"),
    componentManufacturer: FourCharCode("NkHb"),
    componentFlags: 0, componentFlagsMask: 0
  )

  @Test
  func exposesExactlyOneMonoOutputBus() throws {
    let unit = try SortAudioUnit(componentDescription: Self.componentDescription)
    #expect(unit.outputBusses.count == 1)
    #expect(unit.outputBusses[0].format.channelCount == 1)
  }

  @Test
  func rendersNonSilentAudioOnceTheHeadlessDriverStartsProducingEvents() async throws {
    let unit = try SortAudioUnit(componentDescription: Self.componentDescription)
    unit.maximumFramesToRender = 512
    try unit.allocateRenderResources()
    defer { unit.deallocateRenderResources() }

    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    let renderBlock = unit.internalRenderBlock
    var sawNonSilentOutput = false

    // Polls for up to ~400ms — the headless driver's first tick (a ~16ms sleep) needs to fire and
    // enqueue at least one note before any render call can produce real signal.
    for _ in 0..<20 {
      try await Task.sleep(for: .milliseconds(20))
      let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)!
      pcmBuffer.frameLength = 512
      var flags = AudioUnitRenderActionFlags()
      var timestamp = AudioTimeStamp()
      let status = renderBlock(&flags, &timestamp, 512, 0, pcmBuffer.mutableAudioBufferList, nil, nil)
      #expect(status == noErr)

      if let channelData = pcmBuffer.floatChannelData {
        let samples = UnsafeBufferPointer(start: channelData[0], count: 512)
        if samples.contains(where: { $0 != 0 }) {
          sawNonSilentOutput = true
          break
        }
      }
    }

    #expect(sawNonSilentOutput, "expected the headless driver to have produced at least one audible note within 400ms")
  }
}
