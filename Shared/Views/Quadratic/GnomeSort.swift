//
//  GnomeSort.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct GnomeSort: View {
    var body: some View {
        SortView(algorithm: .gnomeSort)
            .navigationTitle("Gnome Sort")
    }
}

struct GnomeSort_Previews: PreviewProvider {
    static var previews: some View {
        GnomeSort()
    }
}
