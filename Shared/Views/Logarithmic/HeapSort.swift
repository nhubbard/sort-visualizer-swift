//
//  HeapSort.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct HeapSort: View {
    var body: some View {
        SortView(algorithm: .heapSort)
            .navigationTitle("Heap Sort")
    }
}

struct HeapSort_Previews: PreviewProvider {
    static var previews: some View {
        HeapSort()
    }
}
