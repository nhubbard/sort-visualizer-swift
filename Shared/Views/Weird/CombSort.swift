//
//  CombSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct CombSort: View {
    var body: some View {
        SortView(algorithm: .combSort)
            .navigationTitle("Comb Sort")
    }
}

struct CombSort_Previews: PreviewProvider {
    static var previews: some View {
        CombSort()
    }
}
