//
//  CodeView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/30/22.
//

import SwiftUI

struct CodeView: View {
  var tokens: [Token]
  
  var body: some View {
    // TODO: Cache this reduce call. Should significantly improve lazy grid performance.
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
