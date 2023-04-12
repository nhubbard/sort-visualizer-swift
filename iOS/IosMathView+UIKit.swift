//
//  MathView+UIKit.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 4/3/23.
//

import Foundation
import SwiftUI
import iosMath

#if os(iOS)
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
#endif
