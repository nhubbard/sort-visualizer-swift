//
//  Algorithms.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/3/22.
//

import Foundation

enum Algorithms: Identifiable, CaseIterable {
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
    // Weird algorithms
    case bitonicSort
    case radixSort
    case shellSort
    case combSort
    case bogoSort
    case stoogeSort
    
    var id: Self { self }
}
