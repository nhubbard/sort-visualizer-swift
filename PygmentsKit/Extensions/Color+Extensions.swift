//
//  Color+Extensions.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import SwiftUI

extension Color {
  /**
   * Convert a sRGB hex color value (stored as a hex-encoded unsigned integer) to a Swift UI Color.
   */
  init(hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 08) & 0xff) / 255,
      blue: Double((hex >> 00) & 0xff) / 255,
      opacity: alpha
    )
  }
}
