//
//  SelectionSort.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct SelectionSort: View {
    var body: some View {
        SortView(algorithm: .selectionSort)
            .navigationTitle("Selection Sort")
    }
}

struct SelectionSort_Previews: PreviewProvider {
    static var previews: some View {
        SelectionSort()
    }
}
