//
//  MonokaiTheme.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

fileprivate let bgColor = Color(fromHex: "#272822")!
fileprivate let text = Color(fromHex: "#F8F8F2")!
fileprivate let errorFg = Color(fromHex: "#960050")!
fileprivate let errorBg = Color(fromHex: "#1E0010")!
fileprivate let comment = Color(fromHex: "#75715E")!
fileprivate let keyword = Color(fromHex: "#66D9EF")!
fileprivate let `operator` = Color(fromHex: "#F92672")!
fileprivate let punctuation = Color(fromHex: "#F8F8F2")!
fileprivate let name = Color(fromHex: "#A6E22E")!
fileprivate let number = Color(fromHex: "#AE81FF")!
fileprivate let string = Color(fromHex: "#E6DB74")!

@frozen public struct MonokaiTheme: CodeTheme {
  func getBgColor() -> Color { bgColor }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: bgColor).then { it in
      switch token {
        case .comment, .commentHashbang, .commentMultiline, .commentPreproc, .commentPreprocFile, .commentSingle, .commentSpecial, .genericSubheading:
          it.fg(comment)
        case .error:
          it.fg(errorFg).bg(errorBg)
        case .escape, .generic, .name, .other, .punctuation, .genericError, .genericHeading, .genericTraceback, .nameBuiltin, .nameEntity, .nameLabel, .nameNamespace, .nameProperty, .nameVariable, .whitespace, .nameBuiltinPseudo, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic:
          it.fg(text)
        case .keyword, .genericOutput, .keywordConstant, .keywordNamespace, .keywordDeclaration, .keywordPseudo, .keywordReserved, .keywordType, .nameConstant:
          it.fg(keyword)
        case .literal, .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .stringEscape, .numberIntegerLong:
          it.fg(number)
        case .operator, .genericDeleted, .nameTag, .operatorWord:
          it.fg(`operator`)
        case .genericEmph:
          it.fg(text).italic()
        case .genericStrong:
          it.fg(text).bold()
        case .genericInserted, .nameAttribute, .nameClass, .nameDecorator, .nameException, .nameFunction, .nameOther, .nameFunctionMagic:
          it.fg(name)
        case .genericPrompt:
          it.fg(`operator`).bold()
        case .literalDate, .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDoc, .stringDouble, .stringHeredoc, .stringInterpol, .stringOther, .stringRegex, .stringSingle, .stringSymbol:
          it.fg(string)
        default:
          it.fg(text)
      }
    }.build()
  }
}
