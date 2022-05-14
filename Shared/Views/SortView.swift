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
    /// UI state
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
                    .alert("Warning", isPresented: $showWarning) {
                        VStack {
                            Text("Either the result returned by the sorting algorithm is incorrect (a bug), or the sorting algorithm is not yet implemented. Sorry!")
                            Button("OK", role: .cancel) {
                                showWarning = false
                            }
                        }
                    }
                GroupBox(label: Label("Settings", systemImage: "gear").padding(.top, 2).padding(.bottom, 2)) {
                    // Settings:
                    // Running and Sound toggles
                    HStack(spacing: 10) {
                        Toggle(isOn: $state.running) {
                            Label("Running", systemImage: "play.fill")
                        }.frame(maxWidth: 150).toggleStyle(.switch).onChange(of: state.running) { newValue in
                            Task.init {
                                if (newValue) {
                                    if (!state.doSort()) {
                                        //showWarning = true
                                        print("Bad result? Maybe. Or maybe we're not waiting enough time.")
                                    }
                                    // TODO: Make sorting functions async and await, because otherwise it will be called while the sorting is still happening.
                                } else {
                                    state.recreate()
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
                            state.recreate()
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
                        Slider(value: $state.arraySizeBacking, in: 16...1024)
                            .onChange(of: state.arraySizeBacking) { newValue in
                                if (state.running) {
                                    state.running = false
                                }
                                state.recreate(numItems: Int(newValue))
                            }
                            .frame(maxWidth: 192)
                        Text(String(format: "%d", state.arraySize.wrappedValue))
                            .foregroundColor(.blue)
                    }
                    Text("Operations: ") + Text("\(state.operations)").foregroundColor(.blue)
                }.background(.black).cornerRadius(15).frame(minWidth: 300, maxWidth: 450, minHeight: 64).padding(.all, 8)
            }
        }.onAppear {
            state.setAlgo(algo: algorithm)
        }
    }
    
    /// Used to generate values at initialization, on array size change, and on recreation.
    static func genData(numItems: Int = 128) -> [SortItem] {
        return (1...numItems).map { SortItem.fromInt(value: $0) }.shuffled()
    }
}

struct SortView_Previews: PreviewProvider {
    static var previews: some View {
        SortView(algorithm: .quickSort)
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (5th generation)"))
            .previewDisplayName("iPad Pro 12.9")
    }
}
