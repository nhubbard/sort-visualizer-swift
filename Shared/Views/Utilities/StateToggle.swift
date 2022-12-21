//
//  StateToggle.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 7/13/22.
//

import SwiftUI

@frozen public struct StateToggle: View {
  var binding: Binding<Bool>
  var name: String
  var iconName: String
  var maxWidth: CGFloat = 150
  
  public var body: some View {
    Toggle(isOn: binding) {
      Label(name, systemImage: iconName)
    }
    .frame(maxWidth: maxWidth)
    .toggleStyle(.switch)
  }
}
