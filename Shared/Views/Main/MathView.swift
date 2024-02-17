//
//  MathView.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 7/7/22.
//

import SwiftUI

@frozen public struct MathView: View {
  public var text: String
  public var unicode: String
  public var math: String

  public var body: some View {
    HStack(spacing: 8) {
      Text("\(text): ")
        .font(.system(size: 16, weight: .bold, design: .default))
        .multilineTextAlignment(.center)
      IosMathView(math: unicode)
    }
  }
}
