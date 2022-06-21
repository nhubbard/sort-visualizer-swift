//
//  BitonicSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct BitonicSort: View {
  var body: some View {
    ScrollingSortView(algorithm: .bitonicSort)
      .navigationTitle("Bitonic Sort")
  }
}

struct BitonicSort_Previews: PreviewProvider {
  static var previews: some View {
    BitonicSort()
  }
}
