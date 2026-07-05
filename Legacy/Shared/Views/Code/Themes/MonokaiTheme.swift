//
//  MonokaiTheme.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

private let bgColor = Color(fromHex: "#272822")!
private let text = Color(fromHex: "#F8F8F2")!
private let errorFg = Color(fromHex: "#960050")!
private let errorBg = Color(fromHex: "#1E0010")!
private let comment = Color(fromHex: "#75715E")!
private let keyword = Color(fromHex: "#66D9EF")!
private let `operator` = Color(fromHex: "#F92672")!
private let punctuation = Color(fromHex: "#F8F8F2")!
private let name = Color(fromHex: "#A6E22E")!
private let number = Color(fromHex: "#AE81FF")!
private let string = Color(fromHex: "#E6DB74")!

@frozen public struct MonokaiTheme: CodeTheme {
  func getBgColor() -> Color { bgColor }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: bgColor).then { it in
      switch token {
        case .comment, .commentHashbang, .commentMultiline, .commentPreproc, .commentPreprocFile, .commentSingle,
             .commentSpecial, .genericSubheading:
          it.fg(comment)
        case .error:
          it.fg(errorFg).bg(errorBg)
        case .escape, .generic, .name, .other, .punctuation, .genericError, .genericHeading, .genericTraceback,
             .nameBuiltin, .nameEntity, .nameLabel, .nameNamespace, .nameProperty, .nameVariable, .whitespace,
             .nameBuiltinPseudo, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic:
          it.fg(text)
        case .keyword, .genericOutput, .keywordConstant, .keywordNamespace, .keywordDeclaration, .keywordPseudo,
             .keywordReserved, .keywordType, .nameConstant:
          it.fg(keyword)
        case .literal, .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .stringEscape,
             .numberIntegerLong:
          it.fg(number)
        case .operator, .genericDeleted, .nameTag, .operatorWord:
          it.fg(`operator`)
        case .genericEmph:
          it.fg(text).italic()
        case .genericStrong:
          it.fg(text).bold()
        case .genericInserted, .nameAttribute, .nameClass, .nameDecorator, .nameException, .nameFunction, .nameOther,
             .nameFunctionMagic:
          it.fg(name)
        case .genericPrompt:
          it.fg(`operator`).bold()
        case .literalDate, .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDoc,
             .stringDouble, .stringHeredoc, .stringInterpol, .stringOther, .stringRegex, .stringSingle, .stringSymbol:
          it.fg(string)
        default:
          it.fg(text)
      }
    }.build()
  }
}
