//
//  ContentView.swift
//  Shared
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct ContentView: View {
    @State var selection: Int?
    
    var body: some View {
        NavigationView {
            // Sidebar content
            List {
                // Homepage
                NavigationLink(destination: HomeView(), tag: 0, selection: self.$selection) {
                    Label("Home", systemImage: "house")
                }
                Divider()
                // Logarithmic sorting algorithms
                Group {
                    Label("Logarithmic", systemImage: "die.face.1").foregroundColor(.blue)
                    NavigationLink(destination: QuickSort(), tag: 1, selection: self.$selection) {
                        Label("Quick Sort", systemImage: "timer")
                    }
                    NavigationLink(destination: MergeSort(), tag: 2, selection: self.$selection) {
                        Label("Merge Sort", systemImage: "arrow.triangle.merge")
                    }
                    NavigationLink(destination: HeapSort(), tag: 3, selection: self.$selection) {
                        Label("Heap Sort", systemImage: "square.stack.3d.forward.dottedline.fill")
                    }
                }
                Divider()
                // Quadratic sorting algorithms
                Group {
                    Label("Quadratic", systemImage: "function").foregroundColor(.blue)
                    NavigationLink(destination: BubbleSort(), tag: 4, selection: self.$selection) {
                        Label("Bubble Sort", systemImage: "bubble.left.fill")
                    }
                    NavigationLink(destination: SelectionSort(), tag: 5, selection: self.$selection) {
                        Label("Selection Sort", systemImage: "selection.pin.in.out")
                    }
                    NavigationLink(destination: InsertionSort(), tag: 6, selection: self.$selection) {
                        Label("Insertion Sort", systemImage: "text.insert")
                    }
                    NavigationLink(destination: GnomeSort(), tag: 7, selection: self.$selection) {
                        Label("Gnome Sort", systemImage: "rectangle.3.group.fill")
                    }
                    NavigationLink(destination: ShakerSort(), tag: 8, selection: self.$selection) {
                        Label("Shaker Sort", systemImage: "crop.rotate")
                    }
                    NavigationLink(destination: OddEvenSort(), tag: 9, selection: self.$selection) {
                        Label("Odd-Even Sort", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill")
                    }
                    NavigationLink(destination: PancakeSort(), tag: 10, selection: self.$selection) {
                        Label("Pancake Sort", systemImage: "camera.metering.multispot")
                    }
                }
                Divider()
                // Weird sorting algorithms
                Group {
                    Label("Weird", systemImage: "camera.metering.unknown").foregroundColor(.blue)
                    NavigationLink(destination: BitonicSort(), tag: 11, selection: self.$selection) {
                        Label("Bitonic Sort", systemImage: "rectangle.2.swap")
                    }
                    NavigationLink(destination: RadixSort(), tag: 12, selection: self.$selection) {
                        Label("Radix Sort", systemImage: "arrow.triangle.swap")
                    }
                    NavigationLink(destination: ShellSort(), tag: 13, selection: self.$selection) {
                        Label("Shell Sort", systemImage: "rectangle.dashed")
                    }
                    NavigationLink(destination: CombSort(), tag: 14, selection: self.$selection) {
                        Label("Comb Sort", systemImage: "comb.fill")
                    }
                    NavigationLink(destination: BogoSort(), tag: 15, selection: self.$selection) {
                        Label("Bogo Sort", systemImage: "shuffle")
                    }
                    NavigationLink(destination: StoogeSort(), tag: 16, selection: self.$selection) {
                        Label("Stooge Sort", systemImage: "desktopcomputer.trianglebadge.exclamationmark")
                    }
                }
            }.onAppear {
                self.selection = 0
            }.padding(.top, 1)
            // Main content
        }
        .listStyle(.sidebar)
        .navigationViewStyle(.columns)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(minWidth: 1000, minHeight: 600)
    }
}
