import AudioToolbox
import AVFoundation
import CoreAudio
import SortAudioBridgeKit
import SortAudioCore
import Synchronization
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
///
/// Also exposes the AU-hosted remote (`AUDIO_UNIT_PLAN.md` §7's "Plug-in UI"): an `AUParameterTree`
/// of audio-production-only DSP controls (envelope ADSR, detune, gain), and
/// `sendRemoteControlCommand(_:)` for the sort-transport buttons (play/pause, restart, etc.),
/// relayed back to the standalone app over the same bridge connection in the opposite direction.
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

  /// The `AUParameterTree`'s `implementorValueProvider` can't safely read `renderer`'s DSP state
  /// directly — `OscillatorDSP`/`EnvelopeDSP` are owned exclusively by the render thread per their
  /// own documented invariant. This snapshot is the source of truth for "what does the host/UI
  /// currently see"; `implementorValueObserver` keeps it in sync with whatever's actually been
  /// enqueued into the renderer.
  private struct ParameterSnapshot {
    var attack: Float = 0.1
    var decay: Float = 0.1
    var sustain: Float = 1.0
    var release: Float = 0.1
    var detune: Float = 0.0
    var gain: Float = 1.0
  }
  private let parameterSnapshot = Mutex(ParameterSnapshot())

  private enum ParameterAddress: AUParameterAddress, CaseIterable {
    case attack, decay, sustain, release, detune, gain
  }

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
    parameterTree = makeParameterTree()
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

  /// The remote's transport buttons call this — a no-op if the bridge never connected, matching
  /// this whole architecture's "no connection = silently does nothing" rule.
  public func sendRemoteControlCommand(_ command: RemoteControlCommand) {
    bridgeClient?.sendRemoteControlCommand(command)
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

  private func makeParameterTree() -> AUParameterTree {
    let snapshot = parameterSnapshot.withLock { $0 }
    let attack = Self.makeParameter(
      identifier: "attack", name: "Attack", address: .attack, min: 0.001, max: 2.0,
      defaultValue: snapshot.attack, unit: .seconds)
    let decay = Self.makeParameter(
      identifier: "decay", name: "Decay", address: .decay, min: 0.001, max: 2.0,
      defaultValue: snapshot.decay, unit: .seconds)
    let sustain = Self.makeParameter(
      identifier: "sustain", name: "Sustain", address: .sustain, min: 0.0, max: 1.0,
      defaultValue: snapshot.sustain, unit: .linearGain)
    let release = Self.makeParameter(
      identifier: "release", name: "Release", address: .release, min: 0.001, max: 2.0,
      defaultValue: snapshot.release, unit: .seconds)
    let detune = Self.makeParameter(
      identifier: "detune", name: "Detune", address: .detune, min: -50.0, max: 50.0,
      defaultValue: snapshot.detune, unit: .hertz)
    let gain = Self.makeParameter(
      identifier: "gain", name: "Gain", address: .gain, min: 0.0, max: 1.0,
      defaultValue: snapshot.gain, unit: .linearGain)

    let tree = AUParameterTree.createTree(withChildren: [attack, decay, sustain, release, detune, gain])
    tree.implementorValueObserver = { [weak self] parameter, value in
      self?.applyParameterChange(address: parameter.address, value: value)
    }
    tree.implementorValueProvider = { [weak self] parameter in
      self?.currentParameterValue(address: parameter.address) ?? 0
    }
    return tree
  }

  private static func makeParameter(
    identifier: String, name: String, address: ParameterAddress,
    min: AUValue, max: AUValue, defaultValue: AUValue, unit: AudioUnitParameterUnit
  ) -> AUParameter {
    let parameter = AUParameterTree.createParameter(
      withIdentifier: identifier, name: name, address: address.rawValue,
      min: min, max: max, unit: unit, unitName: nil,
      flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
    parameter.value = defaultValue
    return parameter
  }

  private func applyParameterChange(address: AUParameterAddress, value: AUValue) {
    guard let address = ParameterAddress(rawValue: address) else { return }
    parameterSnapshot.withLock { snapshot in
      switch address {
      case .attack: snapshot.attack = value
      case .decay: snapshot.decay = value
      case .sustain: snapshot.sustain = value
      case .release: snapshot.release = value
      case .detune: snapshot.detune = value
      case .gain: snapshot.gain = value
      }
    }
    let command: ToneCommand =
      switch address {
      case .attack: .setAttackDuration(value)
      case .decay: .setDecayDuration(value)
      case .sustain: .setSustainLevel(value)
      case .release: .setReleaseDuration(value)
      case .detune: .setDetuningOffset(value)
      case .gain: .setAmplitude(value)
      }
    renderer.enqueue(command)
  }

  private func currentParameterValue(address: AUParameterAddress) -> AUValue {
    guard let address = ParameterAddress(rawValue: address) else { return 0 }
    return parameterSnapshot.withLock { snapshot in
      switch address {
      case .attack: snapshot.attack
      case .decay: snapshot.decay
      case .sustain: snapshot.sustain
      case .release: snapshot.release
      case .detune: snapshot.detune
      case .gain: snapshot.gain
      }
    }
  }
}
