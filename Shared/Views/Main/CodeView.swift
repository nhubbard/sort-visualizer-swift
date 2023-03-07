//
//  CodeView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/30/22.
//

import SwiftUI

// This file shouldn't exist... it's the old code view implementation that caused heap overflows on mobile devices.
// I'm not sure how it still exists. SwiftLint found this file and pointed out issues to me.
// I'm genuinely confused as to where this file is stored at.
struct CodeView: View {
  var tokens: [Token]

  var body: some View {
    tokens.reduce(
      Text("")
        .font(.system(size: 14, weight: .regular, design: .monospaced))
    ) { previous, current in
      previous + Text(current.value)
        .foregroundColor(current.type.color())
        .font(.system(size: 14, weight: .regular, design: .monospaced)) + Text("")
    }
    .padding()
    .fixedSize(horizontal: true, vertical: true)
    .background(codeBgColor)
    .cornerRadius(15)
  }
}
