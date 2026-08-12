import AudioToolbox
import AVFoundation
import Foundation
import SortAudioBridgeKit
import SortAudioCore
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

  /// Renders one 512-frame block and reports whether any sample was non-zero.
  private func renderIsSilent(_ unit: SortAudioUnit, format: AVAudioFormat) -> Bool {
    let renderBlock = unit.internalRenderBlock
    let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)!
    pcmBuffer.frameLength = 512
    var flags = AudioUnitRenderActionFlags()
    var timestamp = AudioTimeStamp()
    _ = renderBlock(&flags, &timestamp, 512, 0, pcmBuffer.mutableAudioBufferList, nil, nil)
    guard let channelData = pcmBuffer.floatChannelData else { return true }
    let samples = UnsafeBufferPointer(start: channelData[0], count: 512)
    return samples.allSatisfy { $0 == 0 }
  }

  /// Companion mode's core contract: with no bridge server reachable (the common case — nothing
  /// self-starts audio anymore), the unit stays silent rather than falling back to any built-in
  /// generator.
  @Test
  func staysSilentWithNoBridgeConnection() throws {
    let unit = try SortAudioUnit(componentDescription: Self.componentDescription)
    unit.maximumFramesToRender = 512
    unit.socketPathOverride = "/tmp/sort-audio-unit-test-unreachable.sock"
    try unit.allocateRenderResources()
    defer { unit.deallocateRenderResources() }

    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    #expect(renderIsSilent(unit, format: format))
  }

  @Test
  func rendersNonSilentAudioOnceABridgeServerBroadcastsAnEvent() async throws {
    let socketPath = "/tmp/sabk-unit-\(UUID().uuidString.prefix(8)).sock"
    defer { try? FileManager.default.removeItem(atPath: socketPath) }
    let server = SortAudioBridgeServer()
    try server.start(socketPath: socketPath)
    defer { server.stop() }

    let unit = try SortAudioUnit(componentDescription: Self.componentDescription)
    unit.maximumFramesToRender = 512
    unit.socketPathOverride = socketPath
    try unit.allocateRenderResources()
    defer { unit.deallocateRenderResources() }

    let deadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !server.hasConnectedClients, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(server.hasConnectedClients)

    server.broadcast(
      SortToneEvent(
        value: 50, range: 1...100, holdSeconds: 10, index: 0, arraySize: 100,
        operationKind: .compare), noteRange: 36...72)
    try await Task.sleep(for: .milliseconds(300))

    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    #expect(!renderIsSilent(unit, format: format))
  }

  /// The remote's "Tone" section (`AUDIO_UNIT_PLAN.md` §7) needs exactly these 6
  /// audio-production-only controls, with correct ranges and defaults matching the DSP's own
  /// hardcoded init values.
  @Test
  func parameterTreeExposesExpectedParametersWithDefaults() throws {
    let unit = try SortAudioUnit(componentDescription: Self.componentDescription)
    guard let tree = unit.parameterTree else {
      Issue.record("expected a parameter tree")
      return
    }
    let expected: [(identifier: String, min: AUValue, max: AUValue, defaultValue: AUValue)] = [
      ("attack", 0.001, 2.0, 0.1),
      ("decay", 0.001, 2.0, 0.1),
      ("sustain", 0.0, 1.0, 1.0),
      ("release", 0.001, 2.0, 0.1),
      ("detune", -50.0, 50.0, 0.0),
      ("gain", 0.0, 1.0, 1.0),
    ]
    #expect(tree.allParameters.count == expected.count)
    for expectation in expected {
      guard let parameter = tree.allParameters.first(where: { $0.identifier == expectation.identifier })
      else {
        Issue.record("missing parameter \(expectation.identifier)")
        continue
      }
      #expect(parameter.minValue == expectation.min)
      #expect(parameter.maxValue == expectation.max)
      #expect(parameter.value == expectation.defaultValue)
    }
  }

  /// Exercises the full observer → `ToneCommand` → `ToneRenderer` pipeline end to end: a real
  /// `AUParameter` value change should actually affect subsequently rendered audio, not just update
  /// some UI-facing cache.
  @Test
  func settingGainParameterToZeroSilencesAnActiveNote() async throws {
    let socketPath = "/tmp/sabk-unit-\(UUID().uuidString.prefix(8)).sock"
    defer { try? FileManager.default.removeItem(atPath: socketPath) }
    let server = SortAudioBridgeServer()
    try server.start(socketPath: socketPath)
    defer { server.stop() }

    let unit = try SortAudioUnit(componentDescription: Self.componentDescription)
    unit.maximumFramesToRender = 512
    unit.socketPathOverride = socketPath
    try unit.allocateRenderResources()
    defer { unit.deallocateRenderResources() }

    let deadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !server.hasConnectedClients, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(server.hasConnectedClients)

    server.broadcast(
      SortToneEvent(
        value: 50, range: 1...100, holdSeconds: 10, index: 0, arraySize: 100,
        operationKind: .compare), noteRange: 36...72)
    try await Task.sleep(for: .milliseconds(300))

    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    #expect(!renderIsSilent(unit, format: format))

    guard let gainParameter = unit.parameterTree?.allParameters.first(where: { $0.identifier == "gain" })
    else {
      Issue.record("expected a gain parameter")
      return
    }
    gainParameter.setValue(0, originator: nil)
    try await Task.sleep(for: .milliseconds(50))

    #expect(renderIsSilent(unit, format: format))
  }
}
