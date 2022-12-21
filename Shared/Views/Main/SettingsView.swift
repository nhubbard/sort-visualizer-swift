//
//  SettingsView.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 11/30/22.
//

import Foundation
import SwiftUI
import Keyboard
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
    return ["C\(octave)", "C♯\(octave)/D♭\(octave)", "D\(octave)", "D♯\(octave)/E♭\(octave)", "E\(octave)", "F\(octave)", "F♯\(octave)/G♭\(octave)", "G\(octave)", "G♯\(octave)/A♭\(octave)", "A\(octave)", "A♯\(octave)/B♭\(octave)", "B\(octave)"]
  }
}
private let noteOptions: [String] = Array([rangeOfNotes(0), rangeOfNotes(1), rangeOfNotes(2), rangeOfNotes(3), rangeOfNotes(4), rangeOfNotes(5), rangeOfNotes(6), rangeOfNotes(7), rangeOfNotes(8)].joined())
private let noteCount = noteOptions.count
// The lowest note is at index 21 in MIDI.
private let noteOffset = 21
private let shuffleOptions: [ShuffleMethod] = [.random, .ascending, .descending, .shuffledCubic, .shuffledQuintic]
private let themeOptions: [CodeThemes] = [.monokai, .pygments, .arduino, .colorful, .dracula, .emacs]

@frozen public struct CustomADSRWidget: UIViewRepresentable {
  public typealias UIViewType = ADSRView
  var initialAttack: AUValue = 0.5
  var initialDecay: AUValue = 0.5
  var initialSustain: AUValue = 0.5
  var initialRelease: AUValue = 0.5
  var callback: (AUValue, AUValue, AUValue, AUValue) -> Void
  let view: ADSRView!
  
  @MainActor
  public init(
    attack: AUValue = 0.5,
    decay: AUValue = 0.5,
    sustain: AUValue = 0.5,
    release: AUValue = 0.5,
    callback: @escaping (AUValue, AUValue, AUValue, AUValue) -> Void
  ) {
    self.initialAttack = attack
    self.initialDecay = decay
    self.initialSustain = sustain
    self.initialRelease = release
    self.callback = callback
    self.view = ADSRView(callback: callback)
  }
  
  public func makeUIView(context _: Context) -> ADSRView {
    view.attack = initialAttack
    view.decay = initialDecay
    view.sustain = initialSustain
    view.release = initialRelease
    // view.bgColor = .systemGray2
    return view
  }
  
  public func updateUIView(_: ADSRView, context _: Context) {
    // This view keeps it's state.
  }
}

struct SettingsView: View {
  @State private var defaultSoundOn: Bool = UserDefaults.standard.sortSoundOn
  @State private var lowestNoteIndex: Int = Int(UserDefaults.standard.synthLowNote)
  @State private var highestNoteIndex: Int = Int(UserDefaults.standard.synthHighNote)
  @State private var synthAmplitude: Float = UserDefaults.standard.synthAmplitude
  @State private var synthAttack: Float = UserDefaults.standard.synthAttack
  @State private var synthDecay: Float = UserDefaults.standard.synthDecay
  @State private var synthSustain: Float = UserDefaults.standard.synthSustain
  @State private var synthRelease: Float = UserDefaults.standard.synthRelease
  @State private var sortDelay: Float = UserDefaults.standard.sortDelay
  @State private var sortArraySize: Int = UserDefaults.standard.sortArraySize
  @State private var sortArraySizeBacking = Float(UserDefaults.standard.sortArraySize)
  @State private var sortArraySizeMin: Int = UserDefaults.standard.sortArraySizeMin
  @State private var sortArraySizeMinBacking: Float = Float(UserDefaults.standard.sortArraySizeMin)
  @State private var sortArraySizeMax: Int = UserDefaults.standard.sortArraySizeMax
  @State private var sortArraySizeMaxBacking: Float = Float(UserDefaults.standard.sortArraySizeMax)
  @State private var sortFormatRuntime: Bool = UserDefaults.standard.sortFormatRuntime
  @State private var sortShuffleMethodIndex: Int = UserDefaults.standard.sortShuffleMethod.rawValue
  @State private var codeThemeIndex: Int = UserDefaults.standard.sortCodeViewTheme.rawValue
  @State private var warnBogoSort: Bool = UserDefaults.standard.bogoShowWarning
  @State private var warnBitonicSort: Bool = UserDefaults.standard.bitonicShowWarning
  
  var body: some View {
    Form {
      Section(header: Text("Synthesizer".uppercased())) {
        // Lowest synth note
        Picker("Lowest synthesizer note", selection: $lowestNoteIndex) {
          ForEach(0..<88) {
            Text(noteOptions[$0])
          }
        }.onChange(of: lowestNoteIndex) { newValue in
          UserDefaults.standard.synthLowNote = UInt8(newValue + noteOffset)
        }
        // Highest synth note
        Picker("Highest synthesizer note", selection: $highestNoteIndex) {
          ForEach(0..<88) {
            Text(noteOptions[$0])
          }
        }.onChange(of: highestNoteIndex) { newValue in
          UserDefaults.standard.synthHighNote = UInt8(newValue + noteOffset)
        }
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $synthAmplitude, in: 0.0...5.0, step: 0.05) { editing in
              if !editing {
                UserDefaults.standard.synthAmplitude = synthAmplitude
              }
            }
            Text(String(format: "%.2f", synthAmplitude))
          }.frame(maxWidth: 350)
        } label: {
          Text("Amplitude")
        }
        LabeledContent {
          CustomADSRWidget(
            attack: synthAttack,
            decay: synthDecay,
            sustain: synthSustain,
            release: synthRelease
          ) { attack, sustain, decay, release in
            synthAttack = attack
            synthSustain = sustain
            synthDecay = decay
            synthRelease = release
          }.padding()
        } label: {
          Text("Attack, decay, sustain, and release")
        }.onChange(of: synthAttack) { newValue in
          UserDefaults.standard.synthAttack = newValue
        }.onChange(of: synthDecay) { newValue in
          UserDefaults.standard.synthDecay = newValue
        }.onChange(of: synthSustain) { newValue in
          UserDefaults.standard.synthSustain = newValue
        }.onChange(of: synthRelease) { newValue in
          UserDefaults.standard.synthRelease = newValue
        }
      }
      Section(header: Text("Sorting".uppercased())) {
        // Sound on by default
        Toggle("Enable sound by default", isOn: $defaultSoundOn)
          .toggleStyle(.switch)
          .onChange(of: defaultSoundOn) { newValue in
            UserDefaults.standard.sortSoundOn = newValue
          }
        // Format running time
        Toggle("Format running time", isOn: $sortFormatRuntime)
          .toggleStyle(.switch)
          .onChange(of: sortFormatRuntime) { newValue in
            UserDefaults.standard.sortFormatRuntime = newValue
          }
        // Default delay
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $sortDelay, in: 0.0...100.0, step: 0.1) { editing in
              if !editing {
                UserDefaults.standard.sortDelay = sortDelay
              }
            }
            Text(String(format: "%.1fms", sortDelay))
          }.frame(maxWidth: 350)
        } label: {
          Text("Default sorting delay")
        }
        // Minimum array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $sortArraySizeMinBacking, in: 4.0...32.0, step: 2) { editing in
              if !editing {
                UserDefaults.standard.sortArraySizeMin = Int(sortArraySizeMinBacking)
              }
            }
            Text("\(Int(sortArraySizeMinBacking))")
          }.frame(maxWidth: 350)
        } label: {
          Text("Minimum array size")
        }
        // Default array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $sortArraySizeBacking, in: sortArraySizeMinBacking...sortArraySizeMaxBacking, step: 2) { editing in
              if !editing {
                UserDefaults.standard.sortArraySize = Int(sortArraySizeBacking)
              }
            }
            Text("\(Int(sortArraySizeBacking))")
          }.frame(maxWidth: 350)
        } label: {
          Text("Default array size")
        }
        // Maximum array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $sortArraySizeMaxBacking, in: 1024.0...4096.0, step: 64) { editing in
              if !editing {
                UserDefaults.standard.sortArraySizeMax = Int(sortArraySizeMaxBacking)
              }
            }
            Text("\(Int(sortArraySizeMaxBacking))")
          }.frame(maxWidth: 350)
        } label: {
          Text("Maximum array size")
        }
        // Shuffle method
        Picker("Shuffle method", selection: $sortShuffleMethodIndex) {
          ForEach(0..<5) {
            Text(shuffleOptions[$0].name)
          }
        }.onChange(of: sortShuffleMethodIndex) { newValue in
          UserDefaults.standard.sortShuffleMethod = ShuffleMethod.fromInt(newValue)
        }
      }
      Section(header: Text("Code".uppercased())) {
        Picker("Code theme", selection: $codeThemeIndex) {
          ForEach(0..<6) {
            Text(themeOptions[$0].name)
          }
        }.onChange(of: codeThemeIndex) { newValue in
          UserDefaults.standard.sortCodeViewTheme = CodeThemes.fromInt(newValue)
        }
      }
      Section(header: Text("Warnings".uppercased())) {
        Toggle("Show bogo sort warning", isOn: $warnBogoSort)
          .toggleStyle(.switch)
          .onChange(of: warnBogoSort) { newValue in
            UserDefaults.standard.bogoShowWarning = newValue
          }
        Toggle("Show bitonic sort warning", isOn: $warnBitonicSort)
          .toggleStyle(.switch)
          .onChange(of: warnBitonicSort) { newValue in
            UserDefaults.standard.bitonicShowWarning = newValue
          }
      }
    }.padding()
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView().frame(minWidth: 800, minHeight: 800).fixedSize()
  }
}
