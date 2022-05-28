//
//  OddEvenSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct OddEvenSort: View {
    var body: some View {
        SortView(algorithm: .oddEvenSort)
            .navigationTitle("Odd-Even Sort")
    }
}

struct OddEvenSort_Previews: PreviewProvider {
    static var previews: some View {
        OddEvenSort()
    }
}
