//
//  CustomIconLabel.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI

@frozen public struct CustomIconLabel: View {
  var text: String
  var iconName: String
  
  public var body: some View {
    Label {
      Text(text)
    } icon: {
      Image.ofAsset(iconName)
    }
  }
}

struct CustomIconLabel_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      CustomIconLabel(text: "Quick Sort", iconName: "quick")
      CustomIconLabel(text: "Merge Sort", iconName: "merge")
      CustomIconLabel(text: "Heap Sort", iconName: "heap")
      CustomIconLabel(text: "Bubble Sort", iconName: "bubble")
      CustomIconLabel(text: "Selection Sort", iconName: "selection")
      CustomIconLabel(text: "Insertion Sort", iconName: "insertion")
      CustomIconLabel(text: "Gnome Sort", iconName: "gnome")
      CustomIconLabel(text: "Shaker Sort", iconName: "shaker")
      CustomIconLabel(text: "Odd-Even Sort", iconName: "odd-even")
      CustomIconLabel(text: "Pancake Sort", iconName: "pancake")
    }
    Group {
      CustomIconLabel(text: "Bitonic Sort", iconName: "bitonic")
      CustomIconLabel(text: "Radix Sort", iconName: "radix")
      CustomIconLabel(text: "Shell Sort", iconName: "shell")
      CustomIconLabel(text: "Comb Sort", iconName: "comb")
      CustomIconLabel(text: "Bogo Sort", iconName: "bogo")
      CustomIconLabel(text: "Stooge Sort", iconName: "stooge")
    }
  }
}
