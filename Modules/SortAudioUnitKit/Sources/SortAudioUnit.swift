import AlgorithmKit
import AudioToolbox
import AVFoundation
import BuiltInAlgorithms
import SortAudioCore
import SortEngineKit
import ToneKitDSP

/// The AUv3 instrument itself — a self-contained, ambient generator per `AUDIO_UNIT_PLAN.md` §1/§7:
/// Logic owns this instance's entire lifetime, with no app UI or `SortSession` in the loop. Reuses
/// exactly the same pieces the standalone app's `AudioEngineKit.AudioService` does
/// (`ToneRenderer`/`LocalToneEventSink`), plus `SortAudioCore.HeadlessSortAudioDriver` to keep
/// producing sort-tone events on its own for as long as the host keeps this instance alive.
///
/// `internalRenderBlock` calls straight into `ToneRenderer.render(...)` — the exact same call
/// `ToneKitAVFoundation.ToneVoice`'s `AVAudioSourceNode` closure already makes for the standalone
/// app, just reached through a different host callback shape. No Objective-C/Objective-C++ shim:
/// modern Swift-only `AUAudioUnit` subclasses calling into allocation-free, lock-free Swift code
/// from the render block are a proven, working pattern, not merely a theoretical one.
public final class SortAudioUnit: AUAudioUnit {
  private let renderer: ToneRenderer
  private let sink: LocalToneEventSink
  private let driver: HeadlessSortAudioDriver
  private var driverTask: Task<Void, Never>?
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
    self.driver = HeadlessSortAudioDriver(sink: sink, noteRange: 36...72)
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    self.outputBus = try AUAudioUnitBus(format: format)
    try super.init(componentDescription: componentDescription, options: options)
  }

  public override var outputBusses: AUAudioUnitBusArray { _outputBusses }

  public override func allocateRenderResources() throws {
    try super.allocateRenderResources()
    renderer.prepare(maxFrameCount: Int(maximumFramesToRender))
    startDriverLoop()
  }

  public override func deallocateRenderResources() {
    driverTask?.cancel()
    driverTask = nil
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

  /// Runs one shuffle+sort to completion, then immediately starts another — the "self-contained,
  /// ambient generator" behavior `AUDIO_UNIT_PLAN.md` §1/§7 settled on, for as long as the host
  /// keeps this instance's render resources allocated. `QuickSort`/`RandomShuffle`/size `256`
  /// (`QuickSort.metadata.sizeRange`'s actual maximum) is a simple, representative default, not a
  /// final answer — Phase 5 replaces this with real AU parameters (algorithm/size selection).
  private func startDriverLoop() {
    driverTask = Task { [driver] in
      while !Task.isCancelled {
        try? await driver.run(
          algorithm: QuickSort(), shuffle: RandomShuffle(), size: 256,
          operationCap: RecordingEngine.defaultOperationCap)
      }
    }
  }
}
