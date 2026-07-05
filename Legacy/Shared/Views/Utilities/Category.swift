//
//  Category.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI

@frozen public struct Category: View {
  var text: String
  var iconName: String
  var isCustomIcon: Bool = true
  var color: Color = .blue

  public var body: some View {
    if isCustomIcon {
      CustomIconLabel(text: text, iconName: iconName).foregroundColor(.blue)
    } else {
      Label(text, systemImage: iconName).foregroundColor(.blue)
    }
  }
}

#Preview {
  Group {
    Category(text: "Logarithmic", iconName: "logarithmic-algos")
    Category(text: "Quadratic", iconName: "quadratic-algos")
    Category(text: "Weird", iconName: "weird-algos")
  }
}
