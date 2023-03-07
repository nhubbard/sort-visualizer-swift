//
//  SettingsView.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 11/30/22.
//

import Foundation
import SwiftUI
import AudioKitUI
import AudioKit
import AVFoundation

private func rangeOfNotes(_ octave: Int) -> [String] {
  precondition((0...8).contains(octave), "Invalid octave: must be 0 <= octave <= 8")
  if octave == 0 {
    return ["A0", "A♯0/B♭0", "B0"]
  } else if octave == 8 {
    return ["C8"]
  } else {
    return ["C\(octave)", "C♯\(octave)/D♭\(octave)", "D\(octave)", "D♯\(octave)/E♭\(octave)", "E\(octave)",
            "F\(octave)", "F♯\(octave)/G♭\(octave)", "G\(octave)", "G♯\(octave)/A♭\(octave)", "A\(octave)",
            "A♯\(octave)/B♭\(octave)", "B\(octave)"]
  }
}
private let noteOptions: [String] = Array([rangeOfNotes(0), rangeOfNotes(1), rangeOfNotes(2), rangeOfNotes(3),
                                           rangeOfNotes(4), rangeOfNotes(5), rangeOfNotes(6), rangeOfNotes(7),
                                           rangeOfNotes(8)].joined())
private let noteCount = noteOptions.count
private let shuffleOptions: [ShuffleMethod] = [.random, .ascending, .descending, .shuffledCubic, .shuffledQuintic]
private let themeOptions: [CodeThemes] = [.monokai, .pygments, .arduino, .colorful, .dracula, .emacs]

@frozen public struct CustomADSRWidget: UIViewRepresentable {
  @AppStorage("synthAttack") var attack: Float = 0.5
  @AppStorage("synthDecay") var decay: Float = 0.5
  @AppStorage("synthSustain") var sustain: Float = 0.5
  @AppStorage("synthRelease") var release: Float = 0.5

  public typealias UIViewType = ADSRView
  var initialAttack: AUValue = 0.5
  var initialDecay: AUValue = 0.5
  var initialSustain: AUValue = 0.5
  var initialRelease: AUValue = 0.5
  let view: ADSRView!

  @MainActor
  public init(
    attack: AUValue = 0.5,
    decay: AUValue = 0.5,
    sustain: AUValue = 0.5,
    release: AUValue = 0.5
  ) {
    self.initialAttack = attack
    self.initialDecay = decay
    self.initialSustain = sustain
    self.initialRelease = release
    self.view = ADSRView()
  }

  public func makeUIView(context _: Context) -> ADSRView {
    view.attack = initialAttack
    view.decay = initialDecay
    view.sustain = initialSustain
    view.release = initialRelease
    view.callback = { newAttack, newDecay, newSustain, newRelease in
      self.attack = newAttack
      self.decay = newDecay
      self.sustain = newSustain
      self.release = newRelease
    }
    // view.bgColor = .systemGray2
    return view
  }

  public func updateUIView(_: ADSRView, context _: Context) {
    view.attack = attack
    view.decay = decay
    view.sustain = sustain
    view.release = release
  }
}

struct SettingsView: View {
  @AppStorage("synthLowNote") private var lowestNoteIndex: Int = 36
  @AppStorage("synthHighNote") private var highestNoteIndex: Int = 72
  @AppStorage("synthAmplitude") private var synthAmplitude: Float = 0.5
  @AppStorage("synthAttack") var attack: Float = 0.5
  @AppStorage("synthDecay") var decay: Float = 0.5
  @AppStorage("synthSustain") var sustain: Float = 0.5
  @AppStorage("synthRelease") var release: Float = 0.5
  @AppStorage("sortSoundOn") private var defaultSoundOn: Bool = false
  @AppStorage("sortDelay") private var sortDelay: Float = 0.1
  @AppStorage("sortArraySize") private var sortArraySize: Int = 256
  @AppStorage("sortArraySizeMin") private var sortArraySizeMin: Int = 16
  @AppStorage("sortArraySizeMax") private var sortArraySizeMax: Int = 2048
  @AppStorage("sortFormatRuntime") private var sortFormatRuntime: Bool = false
  @AppStorage("sortShuffleMethod") private var sortShuffleMethodIndex: Int = 0
  @AppStorage("sortCodeViewTheme") private var codeThemeIndex: Int = 0
  @AppStorage("warnBogoSort") private var warnBogoSort: Bool = true
  @AppStorage("warnBitonicSort") private var warnBitonicSort: Bool = true

  var body: some View {
    Form {
      Section(header: Text("Synthesizer".uppercased())) {
        // Lowest synth note
        Picker("Lowest synthesizer note", selection: $lowestNoteIndex) {
          ForEach(0..<88) {
            Text(noteOptions[$0])
          }
        }
        // Highest synth note
        Picker("Highest synthesizer note", selection: $highestNoteIndex) {
          ForEach(0..<88) {
            Text(noteOptions[$0])
          }
        }
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $synthAmplitude, in: 0.0...5.0, step: 0.05)
            Text(String(format: "%.2f", synthAmplitude))
          }.frame(maxWidth: 350)
        } label: {
          Text("Amplitude")
        }
        LabeledContent {
          CustomADSRWidget().frame(maxWidth: 440, minHeight: 150)
          Button {
            attack = 0.5
            decay = 0.5
            sustain = 0.5
            release = 0.5
          } label: {
            Text("Reset to defaults")
          }
        } label: {
          Text("Attack, decay, sustain, and release")
        }
      }
      Section(header: Text("Sorting".uppercased())) {
        // Sound on by default
        Toggle("Enable sound by default", isOn: $defaultSoundOn)
          .toggleStyle(.switch)
        // Format running time
        Toggle("Format running time", isOn: $sortFormatRuntime)
          .toggleStyle(.switch)
        // Default delay
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $sortDelay, in: 0.0...100.0, step: 0.1)
            Text(String(format: "%.1fms", sortDelay))
          }.frame(maxWidth: 350)
        } label: {
          Text("Default sorting delay")
        }
        // Minimum array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: .convert(from: $sortArraySizeMin), in: 4.0...32.0, step: 2)
            Text("\(sortArraySizeMin)")
          }.frame(maxWidth: 350)
        } label: {
          Text("Minimum array size")
        }
        // Default array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(
              value: .convert(from: $sortArraySize),
              in: Float(sortArraySizeMin)...Float(sortArraySizeMax),
              step: 2
            )
            Text("\(sortArraySize)")
          }.frame(maxWidth: 350)
        } label: {
          Text("Default array size")
        }
        // Maximum array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: .convert(from: $sortArraySizeMax), in: 1024.0...4096.0, step: 64)
            Text("\(sortArraySizeMax)")
          }.frame(maxWidth: 350)
        } label: {
          Text("Maximum array size")
        }
        // Shuffle method
        Picker("Shuffle method", selection: $sortShuffleMethodIndex) {
          ForEach(0..<5) {
            Text(shuffleOptions[$0].name)
          }
        }
      }
      Section(header: Text("Code".uppercased())) {
        Picker("Code theme", selection: $codeThemeIndex) {
          ForEach(0..<6) {
            Text(themeOptions[$0].name)
          }
        }
      }
      Section(header: Text("Warnings".uppercased())) {
        Toggle("Show bogo sort warning", isOn: $warnBogoSort)
          .toggleStyle(.switch)
        Toggle("Show bitonic sort warning", isOn: $warnBitonicSort)
          .toggleStyle(.switch)
      }
    }.padding()
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView().frame(minWidth: 800, minHeight: 800).fixedSize()
  }
}
