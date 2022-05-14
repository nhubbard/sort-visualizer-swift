//
//  QuickSortView.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI
import SpriteKit

struct QuickSort: View {
    var body: some View {
        Group {
            SortView(algorithm: .quickSort)
        }.navigationTitle("Quick Sort")
    }
}

struct QuickSort_Previews: PreviewProvider {
    static var previews: some View {
        QuickSort()
    }
}
