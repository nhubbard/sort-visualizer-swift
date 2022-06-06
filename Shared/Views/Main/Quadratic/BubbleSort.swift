//
//  BubbleSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct BubbleSort: View {
  var body: some View {
    SortView(algorithm: .bubbleSort)
      .navigationTitle("Bubble Sort")
  }
}

struct BubbleSort_Previews: PreviewProvider {
  static var previews: some View {
    BubbleSort()
  }
}
