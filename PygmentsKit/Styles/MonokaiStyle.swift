//
//  MonokaiStyle.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import SwiftUI
import Then

class MonokaiStyle: BaseStyle {
  /// The name of this style.
  var name: String = "monokai"
  
  /// The background color used by this style. Defaults to `.white`.
  var backgroundColor: Color = Color(hex: 0x272822)
  
  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat {
    return TextFormat.getBuilder(bg: backgroundColor).then { it in
      switch tokenType {
        case .keyword, .nameConstant, .genericOutput:
          it.fg(0x66d9ef)
        case .comment, .genericSubheading:
          it.fg(0x75715e)
        case .error:
          it.fg(0x960050).bg(0x1e0010)
        case .nameAttribute, .nameClass, .nameDecorator, .nameException, .nameFunction, .nameOther, .genericInserted:
          it.fg(0xa6e22e)
        case .number, .numberInteger, .numberIntegerLong, .numberBin, .numberHex, .numberOct, .numberFloat, .literal, .stringEscape:
          it.fg(0xae81ff)
        case .literalDate, .string, .stringDoc, .stringChar, .stringAffix, .stringOther, .stringRegex, .stringDouble, .stringSingle, .stringSymbol, .stringHeredoc, .stringBacktick, .stringInterpol, .stringDelimiter:
          it.fg(0xe6db74)
        case .punctuation, .name:
          it.fg(0xf8f8f2)
        case .keywordNamespace, .operator, .nameTag, .genericDeleted:
          it.fg(0xf92672)
        case .genericStrong:
          it.bold()
        case .genericPrompt:
          it.fg(0xf92672).bold()
        case .genericEmph:
          it.italic()
        default:
          it.fg(0xf8f8f2)
      }
    }.build()
  }
}
