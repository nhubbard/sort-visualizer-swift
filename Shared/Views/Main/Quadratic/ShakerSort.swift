//
//  ShakerSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct ShakerSort: View {
    var body: some View {
        SortView(algorithm: .shakerSort)
            .navigationTitle("Shaker Sort")
    }
}

struct ShakerSort_Previews: PreviewProvider {
    static var previews: some View {
        ShakerSort()
    }
}
