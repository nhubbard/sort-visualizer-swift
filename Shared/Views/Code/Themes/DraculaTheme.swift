//
//  DraculaTheme.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

@frozen public struct DraculaTheme: CodeTheme {
  func getBgColor() -> Color { Color(fromHex: "#282a36")! }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: getBgColor()).then { it in
      switch token {
        case .comment, .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .commentSpecial:
          it.fg("#6272a4")
        case .error, .generic, .literal, .name, .other, .punctuation, .genericError, .genericPrompt, .genericStrong,
             .genericTraceback, .literalDate, .nameConstant, .nameDecorator, .nameEntity, .nameException,
             .nameNamespace, .nameOther, .nameProperty:
          it.fg("#f8f8f2")
        case .nameBuiltinPseudo:
          it.fg("#f8f8f2").italic()
        case .genericEmph:
          it.fg("#f8f8f2").underline()
        case .genericHeading, .genericSubheading, .genericInserted:
          it.fg("#f8f8f2").bold()
        case .keyword, .operator, .commentPreproc, .keywordConstant, .keywordNamespace, .keywordPseudo,
             .keywordReserved, .nameTag, .operatorWord:
          it.fg("#ff79c6")
        case .genericDeleted:
          it.fg("#8b080b")
        case .genericOutput:
          it.fg("#44475a")
        case .keywordType:
          it.fg("#8be9fd")
        case .keywordDeclaration, .nameBuiltin, .nameLabel, .nameVariable:
          it.fg("#8be9fd").italic()
        case .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
          it.fg("#ffb86c")
        case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDoc, .stringDouble,
             .stringEscape, .stringHeredoc, .stringInterpol, .stringOther, .stringRegex, .stringSingle,
             .stringSymbol:
          it.fg("#bd93f9")
        case .nameAttribute, .nameClass, .nameFunction, .nameFunctionMagic:
          it.fg("#50fa7b")
        case .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic:
          it.fg("#8be9fd").italic()
        default:
          it.bg("#282a36").fg("#f8f8f2")
      }
    }.build()
  }
}
