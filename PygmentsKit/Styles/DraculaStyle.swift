//
//  DraculaStyle.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import SwiftUI
import Then

class DraculaStyle: BaseStyle {
  /// The name of this style.
  var name: String = "dracula"

  /// The background color used by this style. Defaults to `.white`.
  var backgroundColor: Color = Color(hex: 0x282a36)

  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat {
    TextFormat.getBuilder(bg: backgroundColor).then { it in
      switch tokenType {
        case .whitespace, .generic, .genericError, .genericPrompt, .genericStrong, .genericTraceback, .error, .literal,
             .literalDate, .name, .nameBuiltinPseudo, .nameConstant, .nameDecorator, .nameEntity, .nameException,
             .nameNamespace, .nameOther, .other, .punctuation, .text:
          it.fg(0xf8f8f2)
        case .genericEmph:
          it.fg(0xf8f8f2).underline()
        case .comment, .commentHashbang, .commentMultiline, .commentSingle, .commentSpecial:
          it.fg(0x6272a4)
        case .commentPreproc, .keyword, .keywordConstant, .keywordNamespace, .keywordPseudo, .keywordReserved, .nameTag,
             .operator, .operatorWord:
          it.fg(0xff79c6)
        case .genericDeleted:
          it.fg(0x8b080b)
        case .genericHeading, .genericInserted, .genericSubheading:
          it.fg(0xf8f8f2).bold()
        case .genericOutput:
          it.fg(0x44475a)
        case .keywordDeclaration, .nameBuiltin, .nameLabel, .nameVariable, .nameVariableClass, .nameVariableGlobal,
             .nameVariableInstance:
          it.fg(0x8be9fd).italic()
        case .keywordType:
          it.fg(0x8be9fd)
        case .nameAttribute, .nameClass, .nameFunction:
          it.fg(0x50fa7b)
        case .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberIntegerLong, .numberOct:
          it.fg(0xffb86c)
        case .string, .stringBacktick, .stringChar, .stringDoc, .stringDouble, .stringEscape, .stringHeredoc,
             .stringInterpol, .stringOther, .stringRegex, .stringSingle, .stringSymbol:
          it.fg(0xbd93f9)
        default:
          it.fg(0xffffff)
      }
    }
    .build()
  }
}
