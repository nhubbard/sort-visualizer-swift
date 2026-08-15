import SwiftUI

extension Color {
  /// `rgba`'s byte layout is `0xRRGGBBAA`. `Tools/GenerateThemes/generate_themes.py` parses each
  /// theme's hex strings to this packed form once, in Python, at codegen time, so this never does
  /// any string parsing at runtime — a real profiling run found the string-parsing path this
  /// replaced (`Int(_:radix:)`, `String.index(offsetBy:)`) dominating CPU during Full Sweep,
  /// entirely from `CodeTheme.styles`/`getBgColor()` re-parsing the same handful of hex literals
  /// on every single per-token style lookup.
  public init(rgba: UInt32) {
    let red = CGFloat((rgba >> 24) & 0xFF) / 255.0
    let green = CGFloat((rgba >> 16) & 0xFF) / 255.0
    let blue = CGFloat((rgba >> 8) & 0xFF) / 255.0
    let alpha = CGFloat(rgba & 0xFF) / 255.0
    self.init(CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha))
  }
}
