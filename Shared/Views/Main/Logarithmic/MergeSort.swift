//
//  MergeSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct MergeSort: View {
    var body: some View {
        SortView(algorithm: .mergeSort)
            .navigationTitle("Merge Sort")
    }
}

struct MergeSort_Previews: PreviewProvider {
    static var previews: some View {
        MergeSort()
    }
}
