//
//  Algorithms.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/3/22.
//

import Foundation

enum Algorithms: String, Identifiable, CaseIterable {
  // Logarithmic algorithms
  case quickSort = "quicksort"
  case mergeSort = "mergesort"
  case heapSort = "heapsort"
  // Quadratic algorithms
  case bubbleSort = "bubblesort"
  case selectionSort = "selectionsort"
  case insertionSort = "insertionsort"
  case gnomeSort = "gnomesort"
  case shakerSort = "shakersort"
  case oddEvenSort = "oddevensort"
  case pancakeSort = "pancakesort"
  // Weird algorithms
  case bitonicSort = "bitonicsort"
  case radixSort = "radixsort"
  case shellSort = "shellsort"
  case combSort = "combsort"
  case bogoSort = "bogosort"
  case stoogeSort = "stoogesort"
  
  var id: Self { self }
  var sizeRange: ClosedRange<Float> {
    self == .bogoSort ? 4.0...16.0 : 16.0...512.0
  }
  var defaultSize: Int {
    self == .bogoSort ? 12 : 256
  }
}
