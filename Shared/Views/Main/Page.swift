//
//  Page.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 4/12/23.
//

import Foundation

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
      case .home:          return String(localized: "Home")
      case .settings:      return String(localized: "Settings")
      case .quickSort:     return String(localized: "Quick Sort")
      case .mergeSort:     return String(localized: "Merge Sort")
      case .heapSort:      return String(localized: "Heap Sort")
      case .bubbleSort:    return String(localized: "Bubble Sort")
      case .selectionSort: return String(localized: "Selection Sort")
      case .insertionSort: return String(localized: "Insertion Sort")
      case .gnomeSort:     return String(localized: "Gnome Sort")
      case .shakerSort:    return String(localized: "Shaker Sort")
      case .oddEvenSort:   return String(localized: "Odd-Even Sort")
      case .pancakeSort:   return String(localized: "Pancake Sort")
      case .bitonicSort:   return String(localized: "Bitonic Sort")
      case .radixSort:     return String(localized: "Radix Sort")
      case .shellSort:     return String(localized: "Shell Sort")
      case .combSort:      return String(localized: "Comb Sort")
      case .bogoSort:      return String(localized: "Bogo Sort")
      case .stoogeSort:    return String(localized: "Stooge Sort")
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
