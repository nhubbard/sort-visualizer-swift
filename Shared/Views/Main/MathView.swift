//
//  MathView.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 7/7/22.
//

import SwiftUI
import iosMath

@frozen public struct IosMathView: UIViewRepresentable {
  var math: String

  public func makeUIView(context: Context) -> MTMathUILabel {
    let label = MTMathUILabel()
    label.latex = math
    label.textColor = .white
    return label
  }

  public func updateUIView(_ view: MTMathUILabel, context: Context) {
    // This view does not need state.
  }
}

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
