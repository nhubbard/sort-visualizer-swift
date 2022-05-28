//
//  QuickSortView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI
import SpriteKit

struct QuickSort: View {
    let description = #"""
    Quick Sort is a sorting algorithm based on splitting the data structure into smaller partitions and sorting these partitions recursively until the data structure is sorted.
    
    The partitioning happens from an element known as the *pivot*. All elements greater than the pivot get placed on the right side of the structure. All elements smaller than the pivot get placed on the left side of the structure. This creates two partitions of the list to operate on. This procedure happens recursively until there are only two items in each partition, which are then compared and sorted.
    
    The Quick Sort pivoting strategy is based on a design paradigm known as [divide-and-conquer](https://en.wikipedia.org/wiki/Divide-and-conquer_algorithm). It is a highly performant strategy used by other sorting algorithms, such as merge sort.
    """#
    let averageComplexity = "O(n × log n)"
    let bestCase = "O(n × log n)"
    let worstCase = "O(n²)"
    let spaceComplexity = "O(n)"

    var body: some View {
        ScrollingSortView(algorithm: .quickSort, description: description, averageComplexity: averageComplexity, bestCase: bestCase, worstCase: worstCase, spaceComplexity: spaceComplexity)
            .navigationTitle("Quick Sort")
    }
}

struct QuickSort_Previews: PreviewProvider {
    static var previews: some View {
        QuickSort()
    }
}
