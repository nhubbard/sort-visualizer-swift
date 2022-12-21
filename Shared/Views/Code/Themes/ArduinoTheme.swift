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
fileprivate let comment = Color(fromHex: "#95a5a6")!
// Error
fileprivate let error = Color(fromHex: "#a61717")!
// Keyword, Operator, Comment.Preproc, Keyword.{Declaration,Namespace}, Name.{Builtin,Other,Builtin.Pseudo}, Operator.Word
fileprivate let keyword = Color(fromHex: "#728e00")!
// Name.* not covered by keyword
fileprivate let name = Color(fromHex: "#434f54")!
// Other keywords
fileprivate let otherKeyword = Color(fromHex: "#00979d")!
// Number literals
fileprivate let number = Color(fromHex: "#8a7b52")!
// Strings
fileprivate let string = Color(fromHex: "#7f8c8d")!
// Function names
fileprivate let functionName = Color(fromHex: "#d35400")!

@frozen public struct ArduinoTheme: CodeTheme {
  func getBgColor() -> Color { .white }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: .white).then { it in
      switch token {
        case .comment, .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .commentSpecial:
          it.fg(comment)
        case .error:
          it.fg(error)
        case .keyword, .operator, .commentPreproc, .keywordDeclaration, .keywordNamespace, .nameBuiltin, .nameOther, .operatorWord, .nameBuiltinPseudo:
          it.fg(keyword)
        case .name, .nameAttribute, .nameClass, .nameConstant, .nameDecorator, .nameEntity, .nameException, .nameLabel, .nameNamespace, .nameProperty, .nameTag, .nameVariable, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic:
          it.fg(name)
        case .keywordConstant, .keywordPseudo, .keywordReserved, .keywordType:
          it.fg(otherKeyword)
        case .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
          it.fg(number)
        case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDoc, .stringDouble, .stringEscape, .stringHeredoc, .stringInterpol, .stringOther, .stringRegex, .stringSingle, .stringSymbol:
          it.fg(string)
        case .nameFunction, .nameFunctionMagic:
          it.fg(functionName)
        default:
          it.fg(.black)
      }
    }.build()
  }
}
