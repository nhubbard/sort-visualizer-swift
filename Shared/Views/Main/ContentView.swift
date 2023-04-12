//
//  ContentView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct ContentView: View {
  @State private var selection: Page? = .home

  var body: some View {
    NavigationSplitView {
      List(Page.allCases, selection: $selection) { page in
        if page.isSystemIcon {
          Label(page.displayName, systemImage: page.iconName)
        } else {
          CustomIconLabel(text: page.displayName, iconName: page.iconName)
        }
      }
    } detail: {
      if let selection {
        switch selection {
          case .home: HomeView().navigationTitle(selection.displayName)
          case .settings: SettingsView().navigationTitle(selection.displayName)
          case .quickSort: ScrollingSortView(algorithm: .quickSort).navigationTitle(selection.displayName)
          case .mergeSort: ScrollingSortView(algorithm: .mergeSort).navigationTitle(selection.displayName)
          case .heapSort: ScrollingSortView(algorithm: .heapSort).navigationTitle(selection.displayName)
          case .bubbleSort: ScrollingSortView(algorithm: .bubbleSort).navigationTitle(selection.displayName)
          case .selectionSort: ScrollingSortView(algorithm: .selectionSort).navigationTitle(selection.displayName)
          case .insertionSort: ScrollingSortView(algorithm: .insertionSort).navigationTitle(selection.displayName)
          case .gnomeSort: ScrollingSortView(algorithm: .gnomeSort).navigationTitle(selection.displayName)
          case .shakerSort: ScrollingSortView(algorithm: .shakerSort).navigationTitle(selection.displayName)
          case .oddEvenSort: ScrollingSortView(algorithm: .oddEvenSort).navigationTitle(selection.displayName)
          case .pancakeSort: ScrollingSortView(algorithm: .pancakeSort).navigationTitle(selection.displayName)
          case .bitonicSort: ScrollingSortView(algorithm: .bitonicSort).navigationTitle(selection.displayName)
          case .radixSort: ScrollingSortView(algorithm: .radixSort).navigationTitle(selection.displayName)
          case .shellSort: ScrollingSortView(algorithm: .shellSort).navigationTitle(selection.displayName)
          case .combSort: ScrollingSortView(algorithm: .combSort).navigationTitle(selection.displayName)
          case .bogoSort: ScrollingSortView(algorithm: .bogoSort).navigationTitle(selection.displayName)
          case .stoogeSort: ScrollingSortView(algorithm: .stoogeSort).navigationTitle(selection.displayName)
        }
      } else {
        HomeView()
          .navigationTitle(Page.home.displayName)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().frame(minWidth: 1000, minHeight: 600)
  }
}
