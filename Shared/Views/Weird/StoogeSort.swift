//
//  StoogeSort.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct StoogeSort: View {
    var body: some View {
        SortView(algorithm: .stoogeSort)
            .navigationTitle("Stooge Sort")
    }
}

struct StoogeSort_Previews: PreviewProvider {
    static var previews: some View {
        StoogeSort()
    }
}
