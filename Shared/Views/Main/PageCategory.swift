//
//  PageCategory.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 4/12/23.
//

import Foundation

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
