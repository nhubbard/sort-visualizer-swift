import AudioToolbox
import AVFoundation
import CoreAudio
import SortAudioBridgeKit
import SortAudioCore
import ToneKitDSP
import os

private let logger = Logger(subsystem: "com.nhubbard.Sort2.SortAudioUnitKit", category: "SortAudioUnit")

/// The AUv3 instrument itself — a **companion-mode relay**, not an independent generator
/// (AUDIO_UNIT_PLAN.md's corrected architecture): it never runs a sort of its own. Instead it
/// connects a `SortAudioBridgeClient` to the standalone Sort Symphony app's bridge server (a Unix
/// domain socket inside the shared App Group container) and forwards every event it receives into
/// its own `ToneRenderer` via a `LocalToneEventSink` — the same DSP path
/// `ToneKitAVFoundation.ToneVoice` uses for local playback, reached through a different host
/// callback shape. If the app isn't running or the bridge isn't reachable, this instance is simply
/// silent — there is no self-contained fallback.
///
/// `internalRenderBlock` calls straight into `ToneRenderer.render(...)`. No Objective-C/Objective-
/// C++ shim: modern Swift-only `AUAudioUnit` subclasses calling into allocation-free, lock-free
/// Swift code from the render block are a proven, working pattern.
public final class SortAudioUnit: AUAudioUnit {
  private let renderer: ToneRenderer
  private let sink: LocalToneEventSink
  private var bridgeClient: SortAudioBridgeClient?
  /// Test-only seam: overrides the real App-Group-derived socket path so tests can point this
  /// instance at a local bridge server without needing the real entitlement. Internal, reachable
  /// only via `@testable import` — never set outside tests.
  var socketPathOverride: String?
  private let outputBus: AUAudioUnitBus
  private lazy var _outputBusses = AUAudioUnitBusArray(
    audioUnit: self, busType: .output, busses: [outputBus])

  public override init(
    componentDescription: AudioComponentDescription,
    options: AudioComponentInstantiationOptions = []
  ) throws {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(
        frequency: 440.0, amplitude: 1.0, detuningOffset: 0.0, detuningMultiplier: 1.0),
      envelope: EnvelopeDSP(
        attackDuration: 0.1, decayDuration: 0.1, sustainLevel: 1.0, releaseDuration: 0.1)
    )
    self.renderer = renderer
    self.sink = LocalToneEventSink(renderer: renderer)
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    self.outputBus = try AUAudioUnitBus(format: format)
    try super.init(componentDescription: componentDescription, options: options)
  }

  public override var outputBusses: AUAudioUnitBusArray { _outputBusses }

  public override func allocateRenderResources() throws {
    try super.allocateRenderResources()
    renderer.prepare(maxFrameCount: Int(maximumFramesToRender))
    startBridgeClient()
  }

  public override func deallocateRenderResources() {
    bridgeClient?.stop()
    bridgeClient = nil
    super.deallocateRenderResources()
  }

  public override var internalRenderBlock: AUInternalRenderBlock {
    let renderer = self.renderer
    let sampleRate = outputBus.format.sampleRate
    return { _, _, frameCount, _, outputData, _, _ in
      let buffers = UnsafeMutableAudioBufferListPointer(outputData)
      guard let raw = buffers[0].mData else { return noErr }
      let outBuffer = UnsafeMutableBufferPointer<Float>(
        start: raw.assumingMemoryBound(to: Float.self),
        count: Int(frameCount)
      )
      renderer.render(into: outBuffer, sampleRate: sampleRate)
      return noErr
    }
  }

  /// No-op if the App Group entitlement isn't resolvable (`SortAudioBridgePath.socketPath()`
  /// returns `nil`) — this instance just stays silent rather than crashing, matching companion
  /// mode's "no self-contained fallback" design.
  private func startBridgeClient() {
    guard let socketPath = socketPathOverride ?? SortAudioBridgePath.socketPath() else {
      logger.error("App Group container unavailable — bridge client not started, this instance will stay silent")
      return
    }
    let client = SortAudioBridgeClient(socketPath: socketPath, sink: sink)
    client.start()
    bridgeClient = client
  }
}
