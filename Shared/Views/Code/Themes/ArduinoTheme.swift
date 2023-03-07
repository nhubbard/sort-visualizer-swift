//
//  ArduinoTheme.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

// Comment; Comment.{Hashbang,Multiline,PreprocFile,Single,Special}
private let comment = Color(fromHex: "#95a5a6")!
// Error
private let error = Color(fromHex: "#a61717")!
// Keyword, Operator, Comment.Preproc, Keyword.{Declaration,Namespace}, Name.{Builtin,Other,Builtin.Pseudo},
// Operator.Word
private let keyword = Color(fromHex: "#728e00")!
// Name.* not covered by keyword
private let name = Color(fromHex: "#434f54")!
// Other keywords
private let otherKeyword = Color(fromHex: "#00979d")!
// Number literals
private let number = Color(fromHex: "#8a7b52")!
// Strings
private let string = Color(fromHex: "#7f8c8d")!
// Function names
private let functionName = Color(fromHex: "#d35400")!

@frozen public struct ArduinoTheme: CodeTheme {
  func getBgColor() -> Color { .white }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: .white).then { tokenType in
      switch token {
        case .comment, .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .commentSpecial:
          tokenType.fg(comment)
        case .error:
          tokenType.fg(error)
        case .keyword, .operator, .commentPreproc, .keywordDeclaration, .keywordNamespace, .nameBuiltin, .nameOther,
            .operatorWord, .nameBuiltinPseudo:
          tokenType.fg(keyword)
        case .name, .nameAttribute, .nameClass, .nameConstant, .nameDecorator, .nameEntity, .nameException, .nameLabel,
           .nameNamespace, .nameProperty, .nameTag, .nameVariable, .nameVariableClass, .nameVariableGlobal,
           .nameVariableInstance, .nameVariableMagic:
          tokenType.fg(name)
        case .keywordConstant, .keywordPseudo, .keywordReserved, .keywordType:
          tokenType.fg(otherKeyword)
        case .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
          tokenType.fg(number)
        case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDoc, .stringDouble,
           .stringEscape, .stringHeredoc, .stringInterpol, .stringOther, .stringRegex, .stringSingle, .stringSymbol:
          tokenType.fg(string)
        case .nameFunction, .nameFunctionMagic:
          tokenType.fg(functionName)
        default:
          tokenType.fg(.black)
      }
    }.build()
  }
}
