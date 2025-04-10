//
//  StateToggle.swift
//  Sort Symphony (iOS)
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

#Preview("Checked") {
  StateToggle(binding: Binding {
    true
  } set: { _ in }, name: "Running", iconName: "play.fill")
}

#Preview("Unchecked") {
  StateToggle(binding: Binding {
    false
  } set: { _ in }, name: "Running", iconName: "play.fill")
}
