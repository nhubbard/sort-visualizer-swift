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
  func sixDigitHexParsesAsOpaqueRGB() throws {
    let color = try #require(Color(fromHex: "FF8000"))
    let (r, g, b, a) = components(color)
    #expect(abs(r - 1.0) < 0.01)
    #expect(abs(g - (128.0 / 255.0)) < 0.01)
    #expect(abs(b - 0.0) < 0.01)
    #expect(abs(a - 1.0) < 0.01)
  }

  @Test
  func leadingHashIsStripped() throws {
    let withHash = try #require(Color(fromHex: "#00FF00"))
    let withoutHash = try #require(Color(fromHex: "00FF00"))
    #expect(components(withHash) == components(withoutHash))
  }

  @Test
  func eightDigitHexHonorsAlpha() throws {
    let color = try #require(Color(fromHex: "000000A0"))
    let (_, _, _, a) = components(color)
    #expect(abs(a - (160.0 / 255.0)) < 0.01)
  }

  @Test
  func threeDigitShorthandDoublesEachChannel() throws {
    let shorthand = try #require(Color(fromHex: "F0A"))
    let expanded = try #require(Color(fromHex: "FF00AA"))
    #expect(components(shorthand) == components(expanded))
  }

  @Test
  func fourDigitShorthandDoublesEachChannelIncludingAlpha() throws {
    let shorthand = try #require(Color(fromHex: "F0A8"))
    let expanded = try #require(Color(fromHex: "FF00AA88"))
    #expect(components(shorthand) == components(expanded))
  }

  @Test
  func invalidLengthReturnsNil() {
    #expect(Color(fromHex: "ABCDE") == nil)
    #expect(Color(fromHex: "") == nil)
  }
}

private func == (
  lhs: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat),
  rhs: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
) -> Bool {
  abs(lhs.r - rhs.r) < 0.01 && abs(lhs.g - rhs.g) < 0.01
    && abs(lhs.b - rhs.b) < 0.01 && abs(lhs.a - rhs.a) < 0.01
}
