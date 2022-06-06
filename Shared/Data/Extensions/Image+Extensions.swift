//
//  UIImage+Extensions.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/27/22.
//

import Foundation
import SwiftUI

extension Image {
  static func ofAsset(_ named: String, width: CGFloat = CGFloat(16), height: CGFloat = CGFloat(16)) -> some View {
    return Image(named).resizable(capInsets: .init(), resizingMode: .stretch).frame(width: width, height: height)
  }
}
