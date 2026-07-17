import SwiftUI

/// Ported from `Legacy/Shared/Data/Extensions/Color+Extensions.swift` ("shamelessly stolen from
/// SwifterSwift") — the one piece of hex-color parsing every `CodeTheme` needs.
extension Color {
  private static func getGroupValue(string: String, range: Range<Int>) -> CGFloat {
    let lowerIndex = string.index(string.startIndex, offsetBy: range.lowerBound)
    let upperIndex = string.index(string.startIndex, offsetBy: range.upperBound)
    let group = string[lowerIndex..<upperIndex]
    guard group.count == 2, let intVal = Int(group, radix: 16) else {
      return 1.0
    }
    return CGFloat(Double(intVal) / 255.0)
  }

  public init?(fromHex string: String) {
    let result: String
    if string.first == "#" {
      result = String(string.dropFirst())
    } else {
      result = string
    }
    var stringValue: String = result
    switch stringValue.count {
    case 3:  // RGB
      let r = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 0)])
      let g = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 1)])
      let b = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 2)])
      stringValue = "\(r)\(r)\(g)\(g)\(b)\(b)FF"
    case 4:  // RGBA
      let r = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 0)])
      let g = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 1)])
      let b = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 2)])
      let a = String(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 3)])
      stringValue = "\(r)\(r)\(g)\(g)\(b)\(b)\(a)\(a)"
    case 6:  // RRGGBB
      stringValue += "FF"
    case 8:  // RRGGBBAA
      break
    default:
      return nil
    }
    stringValue = stringValue.lowercased()
    let red = Color.getGroupValue(string: stringValue, range: 0..<2)
    let green = Color.getGroupValue(string: stringValue, range: 2..<4)
    let blue = Color.getGroupValue(string: stringValue, range: 4..<6)
    let alpha = Color.getGroupValue(string: stringValue, range: 6..<8)
    self.init(CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha))
  }
}
