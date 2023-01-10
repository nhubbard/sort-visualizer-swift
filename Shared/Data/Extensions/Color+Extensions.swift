//
//  NSColor+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/30/22.
//

import Foundation
import SwiftUI

/// Shamelessly stolen from SwifterSwift. Thanks for the excellent code!
extension Color {
  private static func getGroupValue(string: String, range: Range<Int>) -> CGFloat {
    // I *hate* string indexing in Swift. I understand that there's a reason pertaining to UTF-16/UTF-8 compatibility... but it's not a good one, in my opinion.
    let group = string[string.index(string.startIndex, offsetBy: range.lowerBound)..<string.index(string.startIndex, offsetBy: range.upperBound)]
    guard group.count == 2,
          let intVal = Int(group, radix: 16) else {
      return 1.0
    }
    return CGFloat(Double(intVal) / 255.0)
  }
  
  init?(fromHex string: String) {
    let result: String
    scope: do {
      if string.first == "#" {
        result = String(string.dropFirst())
        break scope
      }
      result = string
    }
    var stringValue: String = result
    switch stringValue.count {
      case 3: // RGB
        let r = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 0)])
        let g = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 1)])
        let b = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 2)])
        stringValue = "\(r)\(r)\(g)\(g)\(b)\(b)FF"
      case 4: // RGBA
        let r = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 0)])
        let g = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 1)])
        let b = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 2)])
        let a = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 3)])
        stringValue = "\(r)\(r)\(g)\(g)\(b)\(b)\(a)\(a)"
      case 6: // RRGGBB
        stringValue += "FF"
      case 8: // RRGGBBAA
        break
      default:
        return nil
    }
    stringValue = stringValue.lowercased()
    // We now have a string of 4 groups corresponding to RGBA
    let red = Color.getGroupValue(string: stringValue, range: 0..<2)
    let green = Color.getGroupValue(string: stringValue, range: 2..<4)
    let blue = Color.getGroupValue(string: stringValue, range: 4..<6)
    let alpha = Color.getGroupValue(string: stringValue, range: 6..<8)
    self.init(CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha))
  }
}
