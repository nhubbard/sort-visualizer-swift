//
//  SortView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/27/22.
//
import SwiftUI

struct SortView: View {
  var algorithm: Algorithms
  @StateObject var state: SortViewModel = SortViewModel()
  @State private var showStepPopover: Bool = false
  
  var body: some View {
    ZStack {
      GeometryReader { geo in
        let rectWidth = geo.size.width / CGFloat(state.data.count)
        let rectMinHeight = geo.size.height / CGFloat(state.data.count)
        HStack(alignment: .bottom, spacing: 0) {
          ForEach(state.data) { item in
            Rectangle().fill(item.color).frame(width: rectWidth, height: rectMinHeight * CGFloat(item.value))
          }
        }.frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
        GroupBox(label: Label("Settings", systemImage: "gear").padding(.top, 2).padding(.bottom, 2)) {
          // Settings:
          // Running and Sound toggles
          HStack(spacing: 10) {
            // Running toggle
            Toggle(isOn: $state.running) {
              Label("Running", systemImage: "play.fill")
            }.frame(maxWidth: 150).toggleStyle(.switch).onChange(of: state.running, perform: onRunning)
            // Sound toggle
            Toggle(isOn: $state.sound) {
              Label("Sound", systemImage: "speaker.wave.2")
            }.frame(maxWidth: 150).toggleStyle(.switch)
          }.padding(.horizontal, 20)
          // Reset and Step buttons
          HStack(spacing: 10) {
            // Reset button
            Button(action: onReset) {
              Label("Reset", systemImage: "repeat")
            }.frame(maxWidth: 150)
            // Step button
            Button(action: onStep) {
              Label("Step", systemImage: "figure.walk")
            }
              .frame(maxWidth: 150)
              .popover(isPresented: $showStepPopover, arrowEdge: .trailing) {
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
            Slider(value: $state.arraySizeBacking, in: 16...512, step: 2)
              .onChange(of: state.arraySizeBacking, perform: onArraySizeChange)
              .frame(maxWidth: 192)
            Text(String(format: "%d", state.arraySize.wrappedValue))
              .foregroundColor(.blue)
          }
          // Operations counter
          Text("Operations: ") + Text("\(state.getOperations())").foregroundColor(.blue)
        }.background(.black.opacity(0.9)).cornerRadius(15).frame(minWidth: 300, maxWidth: 450, minHeight: 64).padding(.all, 8)
      }
    }
    .onAppear(perform: onRender)
    .alert("Sort Finished Incorrectly", isPresented: $state.showIncompleteWarning, actions: {
      Button("OK", role: .cancel, action: onIncompleteAccept)
    }, message: {
      Text("This can happen in one of two scenarios:\n1. You stopped the algorithm while it was running.\n2. The algorithm implementation has a bug and returned an incorrect result.")
    }).alert("Algorithm Warning", isPresented: $state.showBogoSortWarning, actions: {
      Button("Accept", role: .cancel, action: onBogoAccept)
      Button("Decline", role: .destructive, action: onBogoDecline)
    }, message: {
      Text("Bogo sort will likely never finish sorting.\n\nThis is always true, even on very fast systems with a zero second delay.\n\nIf you leave it running, it will consume system resources, including significant battery life, for a very long time.\n\nIf you wish to continue, press the Accept button; if you wish to stop the sorting, press the Decline button.")
    })
  }
  
  func onRunning(newValue: Bool) {
    // TODO: Start and stop the Synthesizer? Might prevent the occasional popping noise.
    if newValue {
      if algorithm == .bogoSort && !state.bogoSortAccepted {
        state.showBogoSortWarning = true
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
  
  func onReset() {
    // App could crash if reset is clicked while it's running.
    if state.running {
      state.running = false
      if let task = state.sortTaskRef {
        task.cancel()
      }
    }
    state.recreateTaskRef = Task.init {
      await state.recreate()
    }
  }
  
  func onStep() {
    showStepPopover.toggle()
  }
  
  func onArraySizeChange(newValue: Float) {
    if state.running {
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
  
  func onRender() {
    state.setAlgo(algo: algorithm)
  }
}

struct SortView_Previews: PreviewProvider {
  static var previews: some View {
    SortView(algorithm: .quickSort)
      .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (5th generation)"))
      .previewDisplayName("iPad Pro 12.9")
  }
}
