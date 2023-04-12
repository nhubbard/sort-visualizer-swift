//
//  NumberFormatter+Extensions.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 7/26/22.
//

import Foundation

extension NumberFormatter {
  func format(value: Double) -> String? {
    string(from: NSNumber(value: value))
  }
}
