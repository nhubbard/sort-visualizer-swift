//
//  UserDefaults+Extensions.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 11/11/22.
//

import Foundation

extension UserDefaults {
  private enum Keys {
    // Synth keys
    static let synthLowNote = "synthLowNote"
    static let synthHighNote = "synthHighNote"
    static let synthAmplitude = "synthAmplitude"
    static let synthAttack = "synthAttack"
    static let synthDecay = "synthDecay"
    static let synthSustain = "synthSustain"
    static let synthRelease = "synthRelease"
    
    // Sort keys
    static let sortSoundOn = "sortSoundOn"
    static let sortDelay = "sortDelay"
    static let sortArraySize = "sortArraySize"
    static let sortFormatRuntime = "sortFormatRuntime"
    static let sortArraySizeMin = "sortArraySizeMin"
    static let sortArraySizeMax = "sortArraySizeMax"
    static let sortCodeViewTheme = "sortCodeViewTheme"
    // Note: Result should be an enum.
    static let sortShuffleMethod = "sortShuffleMethod"
    
    // Warning keys
    static let bogoShowWarning = "bogoShowWarning"
    static let bitonicShowWarning = "bitonicShowWarning"
  }
  
  // MARK: - Synth Preferences
  
  /// The lowest note the synthesizer is permitted to produce.
  /// Defaults to 36 (MIDI number for C2).
  /// Ranges from 21 (MIDI number for A0, the lowest note on an 88-key piano) to 108 (MIDI number for C8, the highest note on an 88-key piano).
  /// Setter function may fail with a precondition violation in debug builds if the new value isn't in the specified range, or if the new value for the low note is made equal to the current value for the high note.
  var synthLowNote: UInt8 {
    get {
      let value = UInt8(integer(forKey: Keys.synthLowNote))
      return value == UInt8(0) ? UInt8(36) : value
    }
    set(lowNote) {
      precondition((UInt8(21)...UInt8(108)).contains(lowNote), "Low note must be within the MIDI note range of an 88-key piano (21 <= lowNote <= 108).")
      precondition(lowNote != synthHighNote, "Low note and high note cannot be equal!")
      set(Int(lowNote), forKey: Keys.synthLowNote)
    }
  }
  
  /// The highest note the synthesizer is permitted to produce.
  /// Defaults to 72 (MIDI number for C5).
  /// Ranges from 21 (MIDI number for A0, the lowest note on an 88-key piano) to 108 (MIDI number for C8, the highest note on an 88-key piano).
  /// Setter function may fail with a precondition violation in debug builds if the new value isn't in the specified range, or if the new value for the high note is made equal to the current value for the low note.
  var synthHighNote: UInt8 {
    get {
      let value = UInt8(integer(forKey: Keys.synthHighNote))
      return value == UInt8(0) ? UInt8(72) : value
    }
    set(highNote) {
      precondition((UInt8(21)...UInt8(108)).contains(highNote), "High note must be within the MIDI note range of an 88-key piano (21 <= highNote <= 108).")
      precondition(highNote != synthLowNote, "High note and low note cannot be equal!")
      set(Int(highNote), forKey: Keys.synthHighNote)
    }
  }
  
  /// The amplitude produced by the oscillator.
  /// Defaults to 1.0.
  var synthAmplitude: Float {
    get {
      let value = float(forKey: Keys.synthAmplitude)
      return value == 0 ? 1 : value
    }
    set(amplitude) {
      set(amplitude, forKey: Keys.synthAmplitude)
    }
  }
  
  /// The attack duration for the Amplitude Envelope node.
  /// Defaults to 0.5.
  var synthAttack: Float {
    get {
      let value = float(forKey: Keys.synthAttack)
      return value == 0 ? 0.5 : value
    }
    set(attack) {
      set(attack, forKey: Keys.synthAttack)
    }
  }
  
  /// The decay duration for the Amplitude Envelope node.
  /// Defaults to 0.5.
  var synthDecay: Float {
    get {
      let value = float(forKey: Keys.synthDecay)
      return value == 0 ? 0.5 : value
    }
    set(decay) {
      set(decay, forKey: Keys.synthDecay)
    }
  }
  
  /// The sustain level for the Amplitude Envelope node.
  /// Defaults to 0.5.
  var synthSustain: Float {
    get {
      let value = float(forKey: Keys.synthSustain)
      return value == 0 ? 0.5 : value
    }
    set(sustain) {
      set(sustain, forKey: Keys.synthSustain)
    }
  }
  
  /// The release duration for the Amplitude Envelope node.
  /// Defaults to 0.5.
  var synthRelease: Float {
    get {
      let value = float(forKey: Keys.synthRelease)
      return value == 0 ? 0.5 : value
    }
    set(release) {
      set(release, forKey: Keys.synthRelease)
    }
  }
  
  // MARK: - Sort Preferences
  
  /// The default value for the Sound toggle in the SortView.
  /// Defaults to false.
  var sortSoundOn: Bool {
    get {
      bool(forKey: Keys.sortSoundOn)
    }
    set(soundOn) {
      set(soundOn, forKey: Keys.sortSoundOn)
    }
  }
  
  /// The default delay in the SortView.
  /// Defaults to 0.1, for 0.1 milliseconds.
  var sortDelay: Float {
    get {
      let value = float(forKey: Keys.sortDelay)
      return value == 0 ? 0.1 : value
    }
    set(delay) {
      set(delay, forKey: Keys.sortDelay)
    }
  }
  
  /// The default array size in the SortView.
  /// Defaults to 256.
  /// Automatically rounded to the nearest even number.
  var sortArraySize: Int {
    get {
      let value = integer(forKey: Keys.sortArraySize)
      return value == 0 ? 256 : value
    }
    set(arraySize) {
      set(arraySize % 2 == 0 ? arraySize : arraySize + 1, forKey: Keys.sortArraySize)
    }
  }
  
  /// If true, use DateComponentsFormatter to show the runtime in a localized format; if false, use seconds formatted to 1 decimal place for runtime.
  /// Defaults to true (DateComponentsFormatter).
  var sortFormatRuntime: Bool {
    get {
      bool(forKey: Keys.sortFormatRuntime)
    }
    set(formatRuntime) {
      set(formatRuntime, forKey: Keys.sortFormatRuntime)
    }
  }
  
  /// The lowest value of the array size range for normal sorting algorithms (i.e., not bogo sort).
  /// Defaults to 16.
  /// Will be rounded to the nearest even number.
  var sortArraySizeMin: Int {
    get {
      let value = integer(forKey: Keys.sortArraySizeMin)
      return value == 0 ? 16 : value
    }
    set(arraySizeMin) {
      set(arraySizeMin % 2 == 0 ? arraySizeMin : arraySizeMin + 1, forKey: Keys.sortArraySizeMin)
    }
  }
  
  /// The highest value of the array size range for normal sorting algorithms (i.e., not bogo sort).
  /// Defaults to 2048.
  /// Will be rounded to the nearest even number.
  var sortArraySizeMax: Int {
    get {
      let value = integer(forKey: Keys.sortArraySizeMax)
      return value == 0 ? 2048 : value
    }
    set(arraySizeMax) {
      set(arraySizeMax % 2 == 0 ? arraySizeMax : arraySizeMax + 1, forKey: Keys.sortArraySizeMax)
    }
  }
  
  /// The default theme for the code view.
  /// Defaults to "monokai".
  var sortCodeViewTheme: CodeThemes {
    get {
      CodeThemes.fromInt(integer(forKey: Keys.sortCodeViewTheme))
    }
    set(theme) {
      set(theme.rawValue, forKey: Keys.sortCodeViewTheme)
    }
  }
  
  /// The shuffle method to use when generating the array.
  /// Defaults to ShuffleMethod.random.
  var sortShuffleMethod: ShuffleMethod {
    get {
      ShuffleMethod.fromInt(integer(forKey: Keys.sortShuffleMethod))
    }
    set(shuffleMethod) {
      set(shuffleMethod.rawValue, forKey: Keys.sortShuffleMethod)
    }
  }
  
  /// If true, a warning will be shown every time before bogosort is run. If false, the warning will not be shown.
  /// Defaults to true.
  var bogoShowWarning: Bool {
    get {
      bool(forKey: Keys.bogoShowWarning)
    }
    set(show) {
      set(show, forKey: Keys.bogoShowWarning)
    }
  }
  
  /// If true, a warning will be shown the first time bitonic sort is run on every clean launch of the program. If false, it will be skipped.
  /// Defaults to true.
  var bitonicShowWarning: Bool {
    get {
      bool(forKey: Keys.bitonicShowWarning)
    }
    set(show) {
      set(show, forKey: Keys.bitonicShowWarning)
    }
  }
}
