import SwiftUI
import Testing

@testable import DesignSystemKit

private typealias UIAttr = AttributeScopes.SwiftUIAttributes
private typealias UIFont = UIAttr.FontAttribute
private typealias UIUnderline = UIAttr.UnderlineStyleAttribute

@Suite
struct TextFormatTests {
  private static let plainFont: Font = .system(size: 12, weight: .regular, design: .monospaced)

  @Test
  func neitherBoldNorItalicUsesThePlainBaseFont() {
    let container = applyTextFormat(TextFormat())
    #expect(container[UIFont.self] == Self.plainFont)
  }

  @Test
  func boldOnlyBoldsTheBaseFontWithoutItalicizing() {
    let container = applyTextFormat(TextFormat(bold: true))
    #expect(container[UIFont.self] == Self.plainFont.bold())
  }

  @Test
  func italicOnlyItalicizesTheBaseFontWithoutBolding() {
    let container = applyTextFormat(TextFormat(italic: true))
    #expect(container[UIFont.self] == Self.plainFont.italic())
  }

  @Test
  func boldAndItalicTogetherApplyBoth() {
    let container = applyTextFormat(TextFormat(bold: true, italic: true))
    #expect(container[UIFont.self] == Self.plainFont.bold().italic())
  }

  @Test
  func underlineTrueSetsASingleUnderline() {
    let container = applyTextFormat(TextFormat(underline: true))
    #expect(container[UIUnderline.self] == .single)
  }

  @Test
  func underlineFalseLeavesTheUnderlineAttributeUnset() {
    let container = applyTextFormat(TextFormat(underline: false))
    #expect(container[UIUnderline.self] == nil)
  }
}
