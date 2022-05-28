//
//  BogoSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct BogoSort: View {
    var body: some View {
        SortView(algorithm: .bogoSort)
            .navigationTitle("Bogo Sort")
    }
}

struct BogoSort_Previews: PreviewProvider {
    static var previews: some View {
        BogoSort()
    }
}
