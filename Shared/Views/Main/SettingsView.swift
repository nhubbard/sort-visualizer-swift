//
//  SettingsView.swift
//  Sort Symphony (iOS)
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
    return ["A0", "A♯0/B♭0", "B0"].map { it in String(localized: it) }
  } else if octave == 8 {
    return [String(localized: "C8")]
  } else {
    return ["C\(octave)", "C♯\(octave)/D♭\(octave)", "D\(octave)", "D♯\(octave)/E♭\(octave)", "E\(octave)",
            "F\(octave)", "F♯\(octave)/G♭\(octave)", "G\(octave)", "G♯\(octave)/A♭\(octave)", "A\(octave)",
            "A♯\(octave)/B♭\(octave)", "B\(octave)"].map { it in String(localized: it) }
  }
}
private let noteOptions: [String] = Array([rangeOfNotes(0), rangeOfNotes(1), rangeOfNotes(2), rangeOfNotes(3),
                                           rangeOfNotes(4), rangeOfNotes(5), rangeOfNotes(6), rangeOfNotes(7),
                                           rangeOfNotes(8)].joined())
private let shuffleOptions: [ShuffleMethod] = [.random, .ascending, .descending, .shuffledCubic, .shuffledQuintic]
private let themeOptions: [CodeThemes] = [.monokai, .pygments, .arduino, .colorful, .dracula, .emacs]

struct SettingsView: View {
  @AppStorage("synthLowNote", store: .standard) private var lowestNoteIndex: Int = 36
  @AppStorage("synthHighNote", store: .standard) private var highestNoteIndex: Int = 72
  @AppStorage("synthAmplitude", store: .standard) private var synthAmplitude: Float = 0.5
  @AppStorage("synthAttack", store: .standard) var attack: Float = 0.5
  @AppStorage("synthDecay", store: .standard) var decay: Float = 0.5
  @AppStorage("synthSustain", store: .standard) var sustain: Float = 0.5
  @AppStorage("synthRelease", store: .standard) var release: Float = 0.5
  @AppStorage("sortSoundOn", store: .standard) private var defaultSoundOn: Bool = false
  @AppStorage("sortDelay", store: .standard) private var sortDelay: Float = 0.1
  @AppStorage("sortArraySize", store: .standard) private var sortArraySize: Int = 256
  @AppStorage("sortFormatRuntime", store: .standard) private var sortFormatRuntime: Bool = false
  @AppStorage("sortShuffleMethod", store: .standard) private var sortShuffleMethodIndex: Int = 0
  @AppStorage("sortCodeViewTheme", store: .standard) private var codeThemeIndex: Int = 0
  @AppStorage("warnBogoSort", store: .standard) private var warnBogoSort: Bool = true
  @AppStorage("warnBitonicSort", store: .standard) private var warnBitonicSort: Bool = true

  func formatMillis(_ millis: Double) -> String {
    // AudioKit has a "Duration" as well. We have to prefix it for Swift to resolve the Foundation class.
    Swift.Duration.milliseconds(millis)
      .formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 1)))
  }

  var body: some View {
    Form {
      Section(header: Text(String(localized: "SYNTHESIZER"))) {
        // Lowest synth note
        Picker(String(localized: "Lowest synthesizer note"), selection: $lowestNoteIndex) {
          ForEach(0..<88) {
            Text(noteOptions[$0])
          }
        }
        // Highest synth note
        Picker(String(localized: "Highest synthesizer note"), selection: $highestNoteIndex) {
          ForEach(0..<88) {
            Text(noteOptions[$0])
          }
        }
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $synthAmplitude, in: 0.0...5.0, step: 0.05)
            Text(String(format: "%.2f", synthAmplitude))
          }
        } label: {
          Text(String(localized: "Amplitude"))
        }
        #if os(macOS)
        Group {
          LabeledContent {
            HStack(spacing: 8) {
              Slider(value: $attack, in: 0.0...1.0, step: 0.05)
              Text(String(format: "%.2f", attack))
            }
          } label: {
            Text("Attack")
          }
          LabeledContent {
            HStack(spacing: 8) {
              Slider(value: $decay, in: 0.0...1.0, step: 0.05)
              Text(String(format: "%.2f", decay))
            }
          } label: {
            Text("Decay")
          }
          LabeledContent {
            HStack(spacing: 8) {
              Slider(value: $sustain, in: 0.0...1.0, step: 0.05)
              Text(String(format: "%.2f", sustain))
            }
          } label: {
            Text("Sustain")
          }
          LabeledContent {
            HStack(spacing: 8) {
              Slider(value: $release, in: 0.0...1.0, step: 0.05)
              Text(String(format: "%.2f", release))
            }
          } label: {
            Text("Release")
          }
        }
        #else
        LabeledContent {
          VStack {
            CustomADSRWidget().frame(maxWidth: 440, minHeight: 150)
            Button {
              attack = 0.5
              decay = 0.5
              sustain = 0.5
              release = 0.5
            } label: {
              Text(String(localized: "Reset to defaults"))
            }.padding()
          }
        } label: {
          Text(String(localized: "Attack, decay, sustain, and release"))
        }
        #endif
      }
      Section(header: Text(String(localized: "SORTING"))) {
        // Sound on by default
        Toggle(String(localized: "Enable sound by default"), isOn: $defaultSoundOn)
          .toggleStyle(.switch)
        // Format running time
        Toggle(String(localized: "Format running time"), isOn: $sortFormatRuntime)
          .toggleStyle(.switch)
        // Default delay
        LabeledContent {
          HStack(spacing: 8) {
            Slider(value: $sortDelay, in: 0.0...100.0, step: 0.1)
            Text(formatMillis(Double(sortDelay)))
          }.frame(maxWidth: 350)
        } label: {
          Text(String(localized: "Default sorting delay"))
        }
        // Default array size
        LabeledContent {
          HStack(spacing: 8) {
            Slider(
              value: .convert(from: $sortArraySize),
              in: Float(16)...Float(2048),
              step: 2
            )
            Text("\(sortArraySize)")
          }.frame(maxWidth: 350)
        } label: {
          Text(String(localized: "Default array size"))
        }
        // Shuffle method
        Picker(String(localized: "Shuffle method"), selection: $sortShuffleMethodIndex) {
          ForEach(0..<5) {
            Text(String(localized: String.LocalizationValue(shuffleOptions[$0].name)))
          }
        }
      }
      Section(header: Text(String(localized: "CODE"))) {
        Picker(String(localized: "Code theme"), selection: $codeThemeIndex) {
          ForEach(0..<6) {
            Text(themeOptions[$0].name)
          }
        }
      }
      Section(header: Text(String(localized: "WARNINGS"))) {
        Toggle(String(localized: "Show bogo sort warning"), isOn: $warnBogoSort)
          .toggleStyle(.switch)
        Toggle(String(localized: "Show bitonic sort warning"), isOn: $warnBitonicSort)
          .toggleStyle(.switch)
      }
    }
  }
}

#Preview {
  SettingsView()
}
