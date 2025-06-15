//
//  SortView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/27/22.
//

import Foundation
import SwiftUI

struct SortView: View {
  var algorithm: Algorithms
  @StateObject var state: SortViewModel = SortViewModel()

  func formatMillis(_ millis: Double) -> String {
    Duration
      .milliseconds(millis)
      .formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 1)))
  }

  @ViewBuilder
  func bars() -> some View {
    BarLayout(items: state.data) {
      ForEach(state.data) { item in
        Rectangle()
          .fill(item.color)
      }
    }
  }

  @ViewBuilder
  func runningToggle() -> some View {
    StateToggle(binding: $state.running, name: String(localized: "Running"), iconName: "play.fill", maxWidth: 170)
      .accessibilityLabel("Running toggle")
      .onChange(of: state.running, initial: true) { _, newValue in
        onRunning(newValue: newValue)
      }
      .keyboardShortcut("s", modifiers: [.command, .shift])
  }

  @ViewBuilder
  func soundToggle() -> some View {
    StateToggle(binding: $state.sound, name: String(localized: "Sound"), iconName: "speaker.wave.2")
      .accessibilityLabel("Sound toggle")
      .disabled(state.soundDisabled)
      .onChange(of: state.sound, initial: true) { _, newValue in
        onSound(newValue: newValue)
      }
      .keyboardShortcut("a", modifiers: [.command, .shift])
  }

  @ViewBuilder
  func toggleRow() -> some View {
    HStack(spacing: 10) {
      runningToggle()
      soundToggle()
    }.padding(.horizontal, 20)
  }

  @ViewBuilder
  func resetButton() -> some View {
    Button {
      onReset()
    } label: {
      Label(String(localized: "Reset"), systemImage: "repeat")
    }
    .frame(maxWidth: 150)
    .keyboardShortcut("r", modifiers: [.command, .shift])
    .accessibilityLabel("Reset button")
  }

  // FIXME: Uncomment when step function actually works
  /*@ViewBuilder
  func stepButton() -> some View {
    Button {
      onStep()
    } label: {
      Label(String(localized: "Step"), systemImage: "figure.walk")
    }
    .frame(maxWidth: 150)
    .popover(isPresented: $state.showStepPopover, arrowEdge: .trailing) {
      Text(String(localized: "Sorry, this function is not implemented yet."))
        .padding(.all, 4)
    }
    .keyboardShortcut("w", modifiers: [.command, .shift])
    .disabled(state.running)
    .accessibilityLabel("Step button")
  }*/

  @ViewBuilder
  func buttonRow() -> some View {
    HStack(spacing: 10) {
      resetButton()
      // Step button
      // FIXME: stepButton()
    }.padding(.horizontal, 20)
  }

  @ViewBuilder
  func delaySlider() -> some View {
    HStack(spacing: 10) {
      Text(String(localized: "Delay"))
      Slider(value: $state.delay, in: 0...100).frame(maxWidth: 192)
        .accessibilityLabel("Delay slider")
      Text(formatMillis(Double(state.delay)))
        .foregroundColor(.blue)
        .onTapGesture {
          state.showDelayPopup.toggle()
        }
        .accessibilityHint("Formatted delay value")
    }
  }

  @ViewBuilder
  func sizeSlider() -> some View {
    HStack(spacing: 10) {
      Text(String(localized: "Array Size"))
      Slider(value: $state.arraySizeBacking, in: state.sizeRange, step: 2) { editing in
        if !editing {
          onArraySizeChange(newValue: state.arraySizeBacking)
        }
      }.frame(maxWidth: 192).disabled(state.running).accessibilityLabel("Array size slider")
      Text(String(format: "%d", Int(state.arraySizeBacking)))
        .foregroundColor(.blue)
        .onTapGesture {
          state.showArraySizePopup.toggle()
        }
        .accessibilityHint("Formatted array size value")
    }
  }

  var formattedOps: AttributedString {
    var prefix = AttributedString(localized: "Operations: ")
    var ops = AttributedString("\(state.getOperations().formatted(.number.grouping(.automatic)))")
    ops.foregroundColor = .blue
    prefix += ops
    return prefix
  }

  var formattedRuntime: AttributedString {
    var prefix = AttributedString(localized: "Runtime: ")
    var time = AttributedString("\(state.getRunTime())")
    time.foregroundColor = .blue
    prefix += time
    return prefix
  }

  @ViewBuilder
  func opsCounter() -> some View {
    VStack(spacing: 4) {
      Text(formattedOps)
      Text(formattedRuntime).onTapGesture {
        state.sortFormatRuntime.toggle()
      }
    }
  }

  @ViewBuilder
  func settingsBox() -> some View {
    // Note: this uses the Settings page label in the localized strings file.
    GroupBox(label: Label(String(localized: "Settings"), systemImage: "gear").padding(.all, 4)) {
      Group {
          toggleRow()
          buttonRow()
          delaySlider()
          sizeSlider()
          opsCounter()
      }.padding(.all, 2)
    }
      .background(.black.opacity(0.9))
      .cornerRadius(15)
      .frame(minWidth: 300, maxWidth: 450, minHeight: 64)
      .padding([.top, .leading], 16)
      .accessibilityLabel("Settings box")
  }

  var body: some View {
    bars()
      .overlay(alignment: .topLeading) { settingsBox() }
      .onAppear { onRender() }
      .alert(String(localized: "Sort Finished Incorrectly"), isPresented: $state.showIncompleteWarning, actions: {
        Button(String(localized: "OK"), role: .cancel) { onIncompleteAccept() }
      }, message: {
        Text(String(localized: "Sort Finished Incorrectly Message"))
      })
      .alert(String(localized: "Algorithm Warning"), isPresented: $state.showBogoSortWarning, actions: {
        Button(String(localized: "Accept"), role: .cancel) { onBogoAccept() }
        Button(String(localized: "Decline"), role: .destructive) { onBogoDecline() }
      }, message: {
        Text(String(localized: "Bogo Sort Warning Message"))
      })
      .alert(String(localized: "Sound Unavailable"), isPresented: $state.showSoundError, actions: {
        Button(String(localized: "OK"), role: .cancel) { onSoundErrorAccept() }
      }, message: {
        // swiftlint:disable line_length
        Text(String(localized: state.soundErrorText != "" ? "Sound Unavailable Message \(state.soundErrorText)" : "Sound Unavailable Generic Message"))
        // swiftlint:enable line_length
      })
      .alert(String(localized: "Algorithm Warning"), isPresented: $state.showBitonicWarning, actions: {
        Button(String(localized: "OK"), role: .cancel) { onBitonicAccept() }
      }, message: {
        Text(String(localized: "Bitonic Sort Warning Message"))
      })
      .alert(String(localized: "Set Array Size"), isPresented: $state.showArraySizePopup, actions: {
        TextField(String(localized: "New Array Size"), text: $state.newArraySizeValue)
          .autocorrectionDisabled(true)
        #if os(iOS)
          .keyboardType(.asciiCapableNumberPad)
        #endif
        Button(String(localized: "OK")) { onArraySizeChangePopup() }
        Button(String(localized: "Cancel"), role: .cancel) { state.showArraySizePopup.toggle() }
      }, message: {
        Text(String(localized: "Set Array Size Message"))
      })
      .alert(String(localized: "Set Delay"), isPresented: $state.showDelayPopup, actions: {
        TextField(String(localized: "New Delay Value"), text: $state.newDelayValue)
          .autocorrectionDisabled(true)
        #if os(iOS)
          .keyboardType(.asciiCapableNumberPad)
        #endif
        Button(String(localized: "OK")) { onDelayChangePopup() }
        Button(String(localized: "Cancel"), role: .cancel) { state.showDelayPopup.toggle() }
      }, message: {
        Text(String(localized: "New Delay Value Message \(formatMillis(0.0)) to \(formatMillis(100.0))"))
      })
  }

  func onArraySizeChangePopup() {
    state.showArraySizePopup.toggle()
    guard var newValue = Int(state.newArraySizeValue) else { return }
    newValue = min(newValue, 2048)
    newValue = max(newValue, 16)
    if newValue % 2 != 0 {
      newValue += newValue % 2
    }
    state.arraySizeBacking = Float(newValue)
    onArraySizeChange(newValue: state.arraySizeBacking)
  }

  func onDelayChangePopup() {
    state.showDelayPopup.toggle()
    guard var newValue = Float(state.newDelayValue) else { return }
    newValue = min(newValue, 100.0)
    state.delay = newValue
  }

  func onRunning(newValue: Bool) {
    if newValue {
      if algorithm == .bogoSort && !state.bogoSortAccepted && state.enableBogoSortWarning {
        state.showBogoSortWarning = true
      } else if algorithm == .bitonicSort && state.shouldShowBitonicWarning && state.enableBitonicSortWarning {
        state.showBitonicWarning = true
      } else {
        state.sortTaskRef = Task.init(priority: .high) {
          if await !state.doSort() {
            state.showIncompleteWarning = true
          }
        }
      }
    } else {
      state.sortTaskRef?.cancel()
    }
  }

  func onSound(newValue: Bool) {
    Task(priority: .high) { [self] in
      if newValue {
        if case .failure(let error) = await state.toner.start() {
          state.soundErrorText = error.localizedDescription
          state.showSoundError = true
        }
      }
    }
  }

  func onReset() {
    // App could crash if reset is clicked while it's running.
    if state.running {
      state.sortTaskRef?.cancel()
      state.running = false
    }
    state.recreateTaskRef = Task.init(priority: .high) {
      await state.recreate()
    }
  }

  func onStep() {
    state.showStepPopover.toggle()
  }

  func onArraySizeChange(newValue: Float) {
    // Bitonic sort will modify the array size to be a power of two while running.
    // Therefore, it should not stop.
    if state.running && algorithm != .bitonicSort {
      state.running = false
    }
    state.recreateTaskRef = Task.init(priority: .high) {
      await state.recreate(numItems: Int(newValue))
    }
  }

  func onIncompleteAccept() {
    state.showIncompleteWarning = false
  }

  func onBogoAccept() {
    state.bogoSortAccepted = true
    state.showBogoSortWarning = false
    state.running = true
    state.sortTaskRef = Task.init(priority: .high) {
      if await !state.doSort() {
        state.showIncompleteWarning = true
      }
    }
  }

  func onBogoDecline() {
    state.showBogoSortWarning = false
    state.running = false
    state.showIncompleteWarning = false
  }

  func onSoundErrorAccept() {
    state.sound.toggle()
    state.showSoundError = false
    state.soundDisabled = true
  }

  func onBitonicAccept() {
    state.showBitonicWarning = false
    state.shouldShowBitonicWarning = false
    state.running = true
    state.sortTaskRef = Task.init(priority: .high) {
      if await !state.doSort() {
        state.showIncompleteWarning = true
      }
    }
  }

  func onRender() {
    state.setAlgo(algo: algorithm)
    if algorithm == .bogoSort {
      state.sizeRange = Float(4)...Float(16)
      state.arraySizeBacking = Float(12)
      state.data = ShuffleMethod.createSync(maximum: 12)
    }
  }
}

#Preview {
  SortView(algorithm: .quickSort)
}
