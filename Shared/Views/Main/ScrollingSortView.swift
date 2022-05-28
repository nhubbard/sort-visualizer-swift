//
//  ScrollingSortView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI

struct ScrollingSortView: View {
    var algorithm: Algorithms
    
    var body: some View {
        ScrollView {
            SortView(algorithm: algorithm)
            Spacer()
            Text("Description")
                .font(.system(size: 48, weight: .bold, design: .default))
        }
    }
}

struct ScrollingSortView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollingSortView(algorithm: .quickSort)
    }
}
