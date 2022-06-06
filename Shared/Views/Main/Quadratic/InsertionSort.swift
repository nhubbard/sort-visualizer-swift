//
//  InsertionSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct InsertionSort: View {
  var body: some View {
    SortView(algorithm: .insertionSort)
      .navigationTitle("Insertion Sort")
  }
}

struct InsertionSort_Previews: PreviewProvider {
  static var previews: some View {
    InsertionSort()
  }
}
