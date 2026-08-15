import SwiftUI
import Testing

@testable import DesignSystemKit

@Suite
struct ColorHexTests {
  private func components(_ color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
    return (r, g, b, a)
  }

  @Test
  func opaqueRgbaParsesEachChannel() {
    let color = Color(rgba: 0xFF8000FF)
    let (r, g, b, a) = components(color)
    #expect(abs(r - 1.0) < 0.01)
    #expect(abs(g - (128.0 / 255.0)) < 0.01)
    #expect(abs(b - 0.0) < 0.01)
    #expect(abs(a - 1.0) < 0.01)
  }

  @Test
  func rgbaHonorsAlpha() {
    let color = Color(rgba: 0x000000A0)
    let (_, _, _, a) = components(color)
    #expect(abs(a - (160.0 / 255.0)) < 0.01)
  }
}
