//
//  ContentView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

@frozen public enum PageCategory: Identifiable, Hashable, CaseIterable {
  // No category (home, settings page, etc)
  case none
  // Logarithmic algorithms
  case logarithmic
  // Quadratic algorithms
  case quadratic
  // Weird algorithms
  case weird

  public var id: Self { self }

  public var displayName: String {
    switch self {
      case .none: return ""
      case .logarithmic: return "Logarithmic"
      case .quadratic: return "Quadratic"
      case .weird: return "Weird"
    }
  }

  public var iconName: String {
    switch self {
      case .none: return ""
      case .logarithmic: return "logarithmic-algos"
      case .quadratic: return "quadratic-algos"
      case .weird: return "weird-algos"
    }
  }

  public var pages: [Page] {
    switch self {
      case .none: return [.home]
      case .logarithmic: return [.quickSort, .mergeSort, .heapSort]
      case .quadratic: return [.bubbleSort, .selectionSort, .insertionSort, .gnomeSort, .shakerSort, .oddEvenSort,
                               .pancakeSort]
      case .weird: return [.bitonicSort, .radixSort, .shellSort, .combSort, .bogoSort, .stoogeSort]
    }
  }
}

@frozen public enum Page: Identifiable, Hashable, CaseIterable {
  case home
  case settings
  // Logarithmic algorithms
  case quickSort
  case mergeSort
  case heapSort
  // Quadratic algorithms
  case bubbleSort
  case selectionSort
  case insertionSort
  case gnomeSort
  case shakerSort
  case oddEvenSort
  case pancakeSort
  // Weird entries
  case bitonicSort
  case radixSort
  case shellSort
  case combSort
  case bogoSort
  case stoogeSort

  public var id: Self { self }

  public var isSystemIcon: Bool {
    self == .home || self == .settings
  }

  public var algorithm: Algorithms? {
    switch self {
      case .home, .settings: return nil
      case .quickSort:       return .quickSort
      case .mergeSort:       return .mergeSort
      case .heapSort:        return .heapSort
      case .bubbleSort:      return .bubbleSort
      case .selectionSort:   return .selectionSort
      case .insertionSort:   return .insertionSort
      case .gnomeSort:       return .gnomeSort
      case .shakerSort:      return .shakerSort
      case .oddEvenSort:     return .oddEvenSort
      case .pancakeSort:     return .pancakeSort
      case .bitonicSort:     return .bitonicSort
      case .radixSort:       return .radixSort
      case .shellSort:       return .shellSort
      case .combSort:        return .combSort
      case .bogoSort:        return .bogoSort
      case .stoogeSort:      return .stoogeSort
    }
  }

  public var displayName: String {
    switch self {
      case .home:          return "Home"
      case .settings:      return "Settings"
      case .quickSort:     return "Quick Sort"
      case .mergeSort:     return "Merge Sort"
      case .heapSort:      return "Heap Sort"
      case .bubbleSort:    return "Bubble Sort"
      case .selectionSort: return "Selection Sort"
      case .insertionSort: return "Insertion Sort"
      case .gnomeSort:     return "Gnome Sort"
      case .shakerSort:    return "Shaker Sort"
      case .oddEvenSort:   return "Odd-Even Sort"
      case .pancakeSort:   return "Pancake Sort"
      case .bitonicSort:   return "Bitonic Sort"
      case .radixSort:     return "Radix Sort"
      case .shellSort:     return "Shell Sort"
      case .combSort:      return "Comb Sort"
      case .bogoSort:      return "Bogo Sort"
      case .stoogeSort:    return "Stooge Sort"
    }
  }

  public var iconName: String {
    switch self {
      case .home:          return "house"
      case .settings:      return "gear"
      case .quickSort:     return "quick"
      case .mergeSort:     return "merge"
      case .heapSort:      return "heap"
      case .bubbleSort:    return "bubble"
      case .selectionSort: return "selection"
      case .insertionSort: return "insertion"
      case .gnomeSort:     return "gnome"
      case .shakerSort:    return "shaker"
      case .oddEvenSort:   return "odd-even"
      case .pancakeSort:   return "pancake"
      case .bitonicSort:   return "bitonic"
      case .radixSort:     return "radix"
      case .shellSort:     return "shell"
      case .combSort:      return "comb"
      case .bogoSort:      return "bogo"
      case .stoogeSort:    return "stooge"
    }
  }

  public var category: PageCategory {
    switch self {
      case .home, .settings: return .none
      case .quickSort, .mergeSort, .heapSort: return .logarithmic
      case .bubbleSort, .selectionSort, .insertionSort, .gnomeSort, .shakerSort, .oddEvenSort,
           .pancakeSort: return .quadratic
      case .bitonicSort, .radixSort, .shellSort, .combSort, .bogoSort, .stoogeSort: return .weird
    }
  }
}

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
