//
//  QuickSortView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct QuickSort: View {
    let averageComplexity = "O(n × log n)"
    let bestCase = "O(n × log n)"
    let worstCase = "O(n²)"
    let spaceComplexity = "O(n)"

    var body: some View {
        ScrollingSortView(algorithm: .quickSort, entries: [
            ComplexityEntry(key: "Average Complexity", value: averageComplexity),
            ComplexityEntry(key: "Best Case", value: bestCase),
            ComplexityEntry(key: "Worst Case", value: worstCase),
            ComplexityEntry(key: "Space Complexity", value: spaceComplexity)
        ]).navigationTitle("Quick Sort")
    }
}

struct QuickSort_Previews: PreviewProvider {
    static var previews: some View {
        QuickSort()
    }
}
