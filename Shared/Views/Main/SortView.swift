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
  @State var isEditingSize: Bool = false
  
  var body: some View {
    GeometryReader { geo in
      let rectWidth = geo.size.width / CGFloat(state.data.count)
      let rectMinHeight = geo.size.height / CGFloat(state.data.count)
      HStack(alignment: .bottom, spacing: 0) {
        ForEach(state.data) { item in
          Rectangle().fill(item.color).frame(width: rectWidth, height: rectMinHeight * CGFloat(item.value))
        }
      }.frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
    }
    .overlay(alignment: .topLeading) {
      GroupBox(label: Label("Settings", systemImage: "gear").padding(.top, 2).padding(.bottom, 2)) {
        // Running and Sound toggles
        HStack(spacing: 10) {
          // Running toggle
          StateToggle(binding: $state.running, name: "Running", iconName: "play.fill")
            .onChange(of: state.running) { onRunning(newValue: $0) }
          // Sound toggle
          StateToggle(binding: $state.sound, name: "Sound", iconName: "speaker.wave.2")
            .disabled(state.soundDisabled)
            .onChange(of: state.sound) { onSound(newValue: $0) }
        }.padding(.horizontal, 20)
        // Reset and Step buttons
        HStack(spacing: 10) {
          // Reset button
          Button {
            onReset()
          } label: {
            Label("Reset", systemImage: "repeat")
          }.frame(maxWidth: 150)
          // Step button
          Button {
            onStep()
          } label: {
            Label("Step", systemImage: "figure.walk")
          }
          .frame(maxWidth: 150)
          .popover(isPresented: $state.showStepPopover, arrowEdge: .trailing) {
            Text("Sorry, this function is not implemented yet.")
              .padding(.all, 4)
          }
        }.padding(.horizontal, 20)
        // Delay slider
        HStack(spacing: 10) {
          Text("Delay")
          Slider(value: $state.delay, in: 0...100)
            .frame(maxWidth: 192)
          Text(String(format: "%.1f ms", state.delay))
            .foregroundColor(.blue)
        }
        // Array Size slider
        HStack(spacing: 10) {
          Text("Array Size")
          Slider(value: $state.arraySizeBacking, in: state.sizeRange, step: 2) { editing in
              if !editing {
                onArraySizeChange(newValue: state.arraySizeBacking)
              }
            }
              .frame(maxWidth: 192)
              .disabled(state.running)
          Text(String(format: "%d", Int(state.arraySizeBacking)))
            .foregroundColor(.blue)
        }
        // Operations counter
        VStack(spacing: 4) {
          Text("Operations: ") + Text("\(state.getOperations())").foregroundColor(.blue)
          (Text("Runtime: ") + Text(state.getRunTime()).foregroundColor(.blue)).onTapGesture(perform: {
            state.asSeconds.toggle()
          })
        }
      }.background(.black.opacity(0.9)).cornerRadius(15).frame(minWidth: 300, maxWidth: 450, minHeight: 64).padding(.top, 16)
    }
    .onAppear { onRender() }
    .alert("Sort Finished Incorrectly", isPresented: $state.showIncompleteWarning, actions: {
      Button("OK", role: .cancel) { onIncompleteAccept() }
    }, message: {
      Text("This can happen in one of two scenarios:\n1. You stopped the algorithm while it was running.\n2. The algorithm implementation has a bug and returned an incorrect result.")
    }).alert("Algorithm Warning", isPresented: $state.showBogoSortWarning, actions: {
      Button("Accept", role: .cancel) { onBogoAccept() }
      Button("Decline", role: .destructive) { onBogoDecline() }
    }, message: {
      Text("Bogo sort will never finish on any array with more than 12 items.\n\nIf you leave it running, it will consume system resources indefinitely.\n\nAdditionally, if you have photosensitive epilepsy, running bogo sort with a delay of less than 1 millisecond may induce seizures.\n\nIf you wish to continue, press the Accept button; if you wish to stop the sorting, press the Decline button.")
    }).alert("Sound Unavailable", isPresented: $state.showSoundError, actions: {
      Button("OK", role: .cancel) { onSoundErrorAccept() }
    }, message: {
      Text("Sound is unavailable at this time because the Audio Engine returned \(state.soundErrorText != "" ? "the following error during startup: \(state.soundErrorText)" : "an unknown error during startup.")\n\nSound will not be available until the app is restarted and/or any audio-related issue is resolved.")
    }).alert("Algorithm Warning", isPresented: $state.showBitonicWarning, actions: {
      Button("OK", role: .cancel) { onBitonicAccept() }
    }, message: {
      Text("Bitonic sort will fail unless the the array size is a power of two. This is a known limitation of bitonic sort and cannot be worked around.\n\nTo prevent the app from crashing, Sort Visualizer will automatically round the array size to the next highest power of two to prevent errors. This warning will not be shown again while the app is running.\n\nPress OK to continue.")
    })
  }
  
  func onRunning(newValue: Bool) {
    if newValue {
      if algorithm == .bogoSort && !state.bogoSortAccepted {
        state.showBogoSortWarning = true
      } else if algorithm == .bitonicSort && state.shouldShowBitonicWarning {
        state.showBitonicWarning = true
      } else {
        state.sortTaskRef = Task.init {
          if await !state.doSort() {
            state.showIncompleteWarning = true
          }
        }
      }
    } else {
      if let task = state.sortTaskRef {
        task.cancel()
      }
    }
  }
  
  func onSound(newValue: Bool) {
    if newValue {
      Task { [self] in
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
      if let task = state.sortTaskRef {
        task.cancel()
      }
      state.running = false
    }
    state.recreateTaskRef = Task.init {
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
    state.recreateTaskRef = Task.init {
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
    state.sortTaskRef = Task.init {
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
    state.sortTaskRef = Task.init {
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
