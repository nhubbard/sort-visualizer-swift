//
//  IosMathView+AppKit.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/22/24.
//

import Foundation
import SwiftUI
import iosMath

#if os(macOS)
@frozen public struct IosMathView: NSViewRepresentable {
  var math: String

  public func makeNSView(context: Context) -> MTMathUILabel {
    let label = MTMathUILabel()
    label.latex = math
    label.textColor = .white
    return label
  }

  public func updateNSView(_ view: MTMathUILabel, context: Context) {
    // This view does not need state.
  }
}
#endif