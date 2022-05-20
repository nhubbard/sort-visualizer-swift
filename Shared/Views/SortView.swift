//
//  SortView.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/27/22.
//

import SwiftUI

let maxFreq = 600
let minFreq = 200

struct SortView: View {
    var algorithm: Algorithms
    // This warns of global actors or something. We can't fix it for now.
    // Just ignore it.
    @StateObject var state: SortViewModel = SortViewModel()
    @State var showWarning: Bool = false
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                let rectWidth = geo.size.width / CGFloat(state.data.count)
                let rectMinHeight = geo.size.height / CGFloat(state.data.count)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(state.data, id: \.self) { item in
                        Rectangle()
                            .fill(item.color)
                            .frame(width: rectWidth, height: rectMinHeight * CGFloat(item.value))
                    }.id(UUID())
                }.frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
                    .alert("Sort Finished Incorrectly", isPresented: $showWarning, actions: {
                        Button("OK", role: .cancel) {
                            showWarning = false
                        }
                    }, message: {
                        VStack {
                            Text("This can happen when: (a) you stopped the algorithm while it was running; (b) the algorithm implementation has a bug and returned an incorrect result, or; (c) the algorithm isn't implemented at all.")
                        }
                    })
                GroupBox(label: Label("Settings", systemImage: "gear").padding(.top, 2).padding(.bottom, 2)) {
                    // Settings:
                    // Running and Sound toggles
                    HStack(spacing: 10) {
                        Toggle(isOn: $state.running) {
                            Label("Running", systemImage: "play.fill")
                        }.frame(maxWidth: 150).toggleStyle(.switch).onChange(of: state.running) { newValue in
                            DispatchQueue.main.async {
                                if (newValue) {
                                    state.sortTaskRef = Task.init {
                                        if (await !state.doSort()) {
                                            showWarning = true
                                        }
                                    }
                                } else {
                                    if (state.sortTaskRef != nil) {
                                        state.sortTaskRef!.cancel()
                                    }
                                }
                            }
                        }
                        Toggle(isOn: $state.sound) {
                            Label("Sound", systemImage: "speaker.wave.2")
                        }.frame(maxWidth: 150).toggleStyle(.switch)
                    }.padding(.horizontal, 20)
                    // Reset and Step buttons
                    HStack(spacing: 10) {
                        Button(action: {
                            state.recreateTaskRef = Task.init {
                                await state.recreate()
                            }
                        }) {
                            Label("Reset", systemImage: "repeat")
                        }.frame(maxWidth: 150)
                        Button(action: {
                            print("Step button pressed")
                        }) {
                            Label("Step", systemImage: "figure.walk")
                        }.frame(maxWidth: 150)
                    }.padding(.horizontal, 20)
                    HStack(spacing: 10) {
                        Text("Delay")
                        Slider(value: $state.delay, in: 0...100)
                            .frame(maxWidth: 192)
                        Text(String(format: "%.1f ms", state.delay))
                            .foregroundColor(.blue)
                    }
                    HStack(spacing: 10) {
                        Text("Array Size")
                        Slider(value: $state.arraySizeBacking, in: 16...256)
                            .onChange(of: state.arraySizeBacking) { newValue in
                                if (state.running) {
                                    state.running = false
                                }
                                state.recreateTaskRef = Task.init {
                                    await state.recreate(numItems: Int(newValue))
                                }
                            }
                            .frame(maxWidth: 192)
                        Text(String(format: "%d", state.arraySize.wrappedValue))
                            .foregroundColor(.blue)
                    }
                    Text("Operations: ") + Text("\(state.getOperations())").foregroundColor(.blue)
                }.background(.black).cornerRadius(15).frame(minWidth: 300, maxWidth: 450, minHeight: 64).padding(.all, 8)
            }
        }.onAppear {
            state.setAlgo(algo: algorithm)
        }
    }
    
    func onCancelTask() {
        state.running = false
    }
}

struct SortView_Previews: PreviewProvider {
    static var previews: some View {
        SortView(algorithm: .quickSort)
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (5th generation)"))
            .previewDisplayName("iPad Pro 12.9")
    }
}
