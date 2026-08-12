import AudioToolbox
import Observation
import SortAudioCore
import SortAudioUnitKit
import SwiftUI

/// Bridges `SortAudioUnit`'s `AUParameterTree` and `sendRemoteControlCommand(_:)` into SwiftUI —
/// the remote's whole reason for existing (`AUDIO_UNIT_PLAN.md` §7): rapid, audio-production-only
/// control from inside the DAW, nothing else. Registers an `AUParameterObserverToken` so the
/// sliders stay correct if a host automates a parameter externally, not just when the user drags
/// one — the observer callback fires off the main thread, so it hops back before touching UI state.
@Observable
@MainActor
final class SortAudioUnitParameterModel {
  private let audioUnit: SortAudioUnit
  private let parametersByIdentifier: [String: AUParameter]
  private var observerToken: AUParameterObserverToken?

  var attack: Double
  var decay: Double
  var sustain: Double
  var release: Double
  var detune: Double
  var gain: Double

  init(audioUnit: SortAudioUnit) {
    self.audioUnit = audioUnit
    var byIdentifier: [String: AUParameter] = [:]
    for parameter in audioUnit.parameterTree?.allParameters ?? [] {
      byIdentifier[parameter.identifier] = parameter
    }
    self.parametersByIdentifier = byIdentifier
    self.attack = Double(byIdentifier["attack"]?.value ?? 0.1)
    self.decay = Double(byIdentifier["decay"]?.value ?? 0.1)
    self.sustain = Double(byIdentifier["sustain"]?.value ?? 1.0)
    self.release = Double(byIdentifier["release"]?.value ?? 0.1)
    self.detune = Double(byIdentifier["detune"]?.value ?? 0.0)
    self.gain = Double(byIdentifier["gain"]?.value ?? 1.0)

    observerToken = audioUnit.parameterTree?.token(byAddingParameterObserver: { [weak self] address, value in
      Task { @MainActor in
        self?.applyExternalChange(address: address, value: value)
      }
    })
  }

  @MainActor
  private func applyExternalChange(address: AUParameterAddress, value: AUValue) {
    guard let identifier = parametersByIdentifier.first(where: { $0.value.address == address })?.key
    else { return }
    switch identifier {
    case "attack": attack = Double(value)
    case "decay": decay = Double(value)
    case "sustain": sustain = Double(value)
    case "release": release = Double(value)
    case "detune": detune = Double(value)
    case "gain": gain = Double(value)
    default: break
    }
  }

  func setAttack(_ newValue: Double) { attack = newValue; setParameterValue("attack", newValue) }
  func setDecay(_ newValue: Double) { decay = newValue; setParameterValue("decay", newValue) }
  func setSustain(_ newValue: Double) { sustain = newValue; setParameterValue("sustain", newValue) }
  func setRelease(_ newValue: Double) { release = newValue; setParameterValue("release", newValue) }
  func setDetune(_ newValue: Double) { detune = newValue; setParameterValue("detune", newValue) }
  func setGain(_ newValue: Double) { gain = newValue; setParameterValue("gain", newValue) }

  private func setParameterValue(_ identifier: String, _ newValue: Double) {
    parametersByIdentifier[identifier]?.setValue(AUValue(newValue), originator: observerToken)
  }

  func send(_ command: RemoteControlCommand) {
    audioUnit.sendRemoteControlCommand(command)
  }
}

/// The remote itself — two sections, nothing else. No sort visualization, algorithm detail, or code
/// display: Transport just fires fire-and-forget commands at the running standalone app; Tone
/// exposes only the DSP controls `ToneKitDSP` already models (envelope ADSR, detune, gain).
struct SortAudioUnitParameterView: View {
  @State private var model: SortAudioUnitParameterModel

  init(audioUnit: SortAudioUnit) {
    _model = State(initialValue: SortAudioUnitParameterModel(audioUnit: audioUnit))
  }

  var body: some View {
    Form {
      Section("Transport") {
        HStack {
          transportButton("Restart", systemImage: "backward.end.fill") { model.send(.restart) }
          transportButton("Play / Pause", systemImage: "playpause.fill") { model.send(.togglePlayback) }
          transportButton("Regenerate", systemImage: "shuffle") { model.send(.regenerate) }
        }
        HStack {
          transportButton("Step Back", systemImage: "backward.frame.fill") { model.send(.stepBackward) }
          transportButton("Step Forward", systemImage: "forward.frame.fill") { model.send(.stepForward) }
          transportButton("Sound", systemImage: "speaker.wave.2.fill") { model.send(.toggleSound) }
        }
      }
      Section("Tone") {
        toneSlider("Attack", value: model.attack, range: 0.001...2.0, unit: "s", set: model.setAttack)
        toneSlider("Decay", value: model.decay, range: 0.001...2.0, unit: "s", set: model.setDecay)
        toneSlider("Sustain", value: model.sustain, range: 0...1, unit: "", set: model.setSustain)
        toneSlider("Release", value: model.release, range: 0.001...2.0, unit: "s", set: model.setRelease)
        toneSlider("Detune", value: model.detune, range: -50...50, unit: "Hz", set: model.setDetune)
        toneSlider("Gain", value: model.gain, range: 0...1, unit: "", set: model.setGain)
      }
    }
  }

  private func transportButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack {
        Image(systemName: systemImage)
        Text(title).font(.caption2)
      }
      .frame(maxWidth: .infinity)
    }
  }

  private func toneSlider(
    _ title: String, value: Double, range: ClosedRange<Double>, unit: String, set: @escaping (Double) -> Void
  ) -> some View {
    VStack(alignment: .leading) {
      Text("\(title): \(String(format: "%.3f", value))\(unit)")
        .font(.caption)
        .foregroundStyle(.secondary)
      Slider(
        value: Binding(get: { value }, set: set),
        in: range
      )
    }
  }
}
