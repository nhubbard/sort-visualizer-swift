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
  @Namespace private var ns

  func formatMillis(_ v: Float) -> String {
    Duration
      .milliseconds(Double(v))
      .formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 1)))
  }

  func formatCount(_ v: Float) -> String {
    String(Int(v))
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
  func delaySlider() -> some View {
    HStack(spacing: 10) {
      Text(String(localized: "Delay"))
      Slider(value: $state.delay, in: 0...100).frame(maxWidth: 192)
        .accessibilityLabel("Delay slider")
      Text(formatMillis(state.delay))
        .foregroundColor(.blue)
        .onTapGesture {
          state.showDelayPopup.toggle()
        }
        .accessibilityHint("Formatted delay value")
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

  var body: some View {
    bars()
      .overlay(alignment: .topLeading) {
        VStack {
          HStack(spacing: 4) {
            Button {
              withAnimation(.interactiveSpring()) {
                state.running.toggle()
                onRunning(newValue: state.running)
              }
            } label: {
              HStack {
                Group {
                  Image(systemName: state.running ? "pause.fill" : "play.fill")
                    .matchedGeometryEffect(id: "startStopIcon", in: ns)
                  Text(state.running ? "Stop" : "Start")
                    .matchedGeometryEffect(id: "startStopText", in: ns)
                }
              }
            }.controlSize(.large).glassEffect(.regular.interactive())
            Button {
              withAnimation(.interactiveSpring()) {
                state.sound.toggle()
                onSound(newValue: state.sound)
              }
            } label: {
              HStack {
                Group {
                  Image(systemName: state.sound ? "speaker.slash.fill" : "speaker.wave.3.fill")
                    .matchedGeometryEffect(id: "soundIcon", in: ns)
                  Text(state.sound ? "Turn Sound Off" : "Turn Sound On")
                    .matchedGeometryEffect(id: "soundText", in: ns)
                }
              }
            }.controlSize(.large).glassEffect(.regular.interactive())
            Button {
              onReset()
            } label: {
              Label {
                Text("Reset")
              } icon: {
                Image(systemName: "arrow.clockwise")
              }
            }.controlSize(.large).glassEffect(.regular.interactive())
            TouchBarSlider(
              value: $state.arraySizeBacking,
              range: state.sizeRange,
              step: 2,
              formatter: formatCount
            ) {
              Label("Array Size", systemImage: "square.resize")
            }
            .disabled(state.running)
            .onChange(of: state.arraySizeBacking) { _, newVal in
              onArraySizeChange(newValue: newVal)
            }
            .glassEffect()
            TouchBarSlider(
              value: $state.delay,
              range: 0.0...100.0,
              step: 1.0,
              formatter: formatMillis
            ) {
              Label("Delay", systemImage: "stopwatch")
            }
            .glassEffect()
          }.padding([.all], 16)
          Button("") {
            state.showArraySizePopup.toggle()
          }.keyboardShortcut("r", modifiers: [.command]).hidden()
        }
      }
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
