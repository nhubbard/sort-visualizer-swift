//
//  ContentView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

fileprivate let logEntries: [AlgorithmEntry] = [
    AlgorithmEntry(name: "Quick Sort", icon: "quick", destination: AnyView(QuickSort()), tag: 1),
    AlgorithmEntry(name: "Merge Sort", icon: "merge", destination: AnyView(MergeSort()), tag: 2),
    AlgorithmEntry(name: "Heap Sort", icon: "heap", destination: AnyView(HeapSort()), tag: 3)
]

fileprivate let quadraticEntries: [AlgorithmEntry] = [
    AlgorithmEntry(name: "Bubble Sort", icon: "bubble", destination: AnyView(BubbleSort()), tag: 4),
    AlgorithmEntry(name: "Selection Sort", icon: "selection", destination: AnyView(SelectionSort()), tag: 5),
    AlgorithmEntry(name: "Insertion Sort", icon: "insertion", destination: AnyView(InsertionSort()), tag: 6),
    AlgorithmEntry(name: "Gnome Sort", icon: "gnome", destination: AnyView(GnomeSort()), tag: 7),
    AlgorithmEntry(name: "Shaker Sort", icon: "shaker", destination: AnyView(ShakerSort()), tag: 8),
    AlgorithmEntry(name: "Odd-Even Sort", icon: "odd-even", destination: AnyView(OddEvenSort()), tag: 9),
    AlgorithmEntry(name: "Pancake Sort", icon: "pancake", destination: AnyView(PancakeSort()), tag: 10)
]

fileprivate let weirdEntries: [AlgorithmEntry] = [
    AlgorithmEntry(name: "Bitonic Sort", icon: "bitonic", destination: AnyView(BitonicSort()), tag: 11),
    AlgorithmEntry(name: "Radix Sort", icon: "radix", destination: AnyView(RadixSort()), tag: 12),
    AlgorithmEntry(name: "Shell Sort", icon: "shell", destination: AnyView(ShellSort()), tag: 13),
    AlgorithmEntry(name: "Comb Sort", icon: "comb", destination: AnyView(CombSort()), tag: 14),
    AlgorithmEntry(name: "Bogo Sort", icon: "bogo", destination: AnyView(BogoSort()), tag: 15),
    AlgorithmEntry(name: "Stooge Sort", icon: "stooge", destination: AnyView(StoogeSort()), tag: 16)
]

struct ContentView: View {
    @State var selection: Int? = 0
    
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
                    Category(text: "Logarithmic", iconName: "logarithmic-algos")
                    ForEach(logEntries, id: \.self) { entry in
                        NavigationLink(destination: entry.destination, tag: entry.tag, selection: self.$selection) {
                            CustomIconLabel(text: entry.name, iconName: entry.icon)
                        }
                    }
                }
                Divider()
                // Quadratic sorting algorithms
                Group {
                    Category(text: "Quadratic", iconName: "quadratic-algos")
                    ForEach(quadraticEntries, id: \.self) { entry in
                        NavigationLink(destination: entry.destination, tag: entry.tag, selection: self.$selection) {
                            CustomIconLabel(text: entry.name, iconName: entry.icon)
                        }
                    }
                }
                Divider()
                // Weird sorting algorithms
                Group {
                    Category(text: "Weird", iconName: "weird-algos")
                    ForEach(weirdEntries, id: \.self) { entry in
                        NavigationLink(destination: entry.destination, tag: entry.tag, selection: self.$selection) {
                            CustomIconLabel(text: entry.name, iconName: entry.icon)
                        }
                    }
                }
            }.padding(.top, 1)
        }.listStyle(.sidebar).navigationViewStyle(.columns)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().frame(minWidth: 1000, minHeight: 600)
    }
}
