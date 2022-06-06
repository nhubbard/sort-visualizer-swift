//
//  QuickSortView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct QuickSort: View {
  var body: some View {
    ScrollingSortView(algorithm: .quickSort).navigationTitle("Quick Sort")
  }
}

struct QuickSort_Previews: PreviewProvider {
  static var previews: some View {
    QuickSort()
  }
}
