//
//  ShellSort.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI

struct ShellSort: View {
  var body: some View {
    SortView(algorithm: .shellSort)
      .navigationTitle("Shell Sort")
  }
}

struct ShellSort_Previews: PreviewProvider {
  static var previews: some View {
    ShellSort()
  }
}
