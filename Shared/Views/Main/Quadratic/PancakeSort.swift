//
//  PancakeSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct PancakeSort: View {
  var body: some View {
    SortView(algorithm: .pancakeSort)
      .navigationTitle("Pancake Sort")
  }
}

struct PancakeSort_Previews: PreviewProvider {
  static var previews: some View {
    PancakeSort()
  }
}
