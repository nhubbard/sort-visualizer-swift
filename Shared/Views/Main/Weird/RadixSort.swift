//
//  RadixSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct RadixSort: View {
  var body: some View {
    SortView(algorithm: .radixSort)
      .navigationTitle("Radix Sort")
  }
}

struct RadixSort_Previews: PreviewProvider {
  static var previews: some View {
    RadixSort()
  }
}
