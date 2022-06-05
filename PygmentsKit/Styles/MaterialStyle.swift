//
//  MaterialStyle.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import SwiftUI
import Then

class MaterialStyle: BaseStyle {
  /// The name of this style.
  var name: String = "default"
  
  /// The background color used by this style. Defaults to `.white`.
  var backgroundColor: Color = Color(hex: 0x263238)
  
  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat {
    return TextFormat.getBuilder(bg: backgroundColor).then { it in
      switch tokenType {
        case .genericOutput:
          it.fg(0x546e7a)
        case .nameBuiltin, .nameDecorator, .nameFunction, .nameFunctionMagic, .nameLabel, .nameVariableMagic:
          it.fg(0x82aaff)
        case .escape, .keywordConstant, .keywordPseudo, .nameBuiltinPseudo, .nameEntity, .nameVariable, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .stringInterpol, .stringRegex, .stringSymbol, .operator, .punctuation, .genericEmph, .genericSubheading:
          it.fg(0x89ddff)
        case .keyword, .keywordDeclaration, .keywordType, .nameAttribute, .stringAffix:
          it.fg(0xbb80b3)
        case .literal, .literalDate, .string, .stringBacktick, .stringChar, .stringDouble, .stringHeredoc, .stringOther, .stringSingle, .genericHeading, .genericInserted:
          it.fg(0xc3e88d)
        case .text, .name, .nameConstant, .nameOther, .stringDelimiter, .stringEscape, .generic:
          it.fg(0xeeffff)
        case .number, .numberInteger, .numberIntegerLong, .numberBin, .numberHex, .numberOct, .numberFloat:
          it.fg(0xf78c6c)
        case .error, .nameTag, .genericDeleted, .genericError, .genericStrong, .genericTraceback:
          it.fg(0xff5370)
        case .nameClass, .nameException, .nameProperty, .nameNamespace, .genericPrompt:
          it.fg(0xffcb6b)
        case .stringDoc, .comment, .commentPreproc, .commentPreprocFile, .commentSingle, .commentSpecial, .commentHashbang, .commentMultiline:
          it.fg(0x546e7a).italic()
        case .keywordNamespace, .operatorWord:
          it.fg(0x89ddff).italic()
        default:
          it.fg(0xeeffff)
      }
    }.build()
  }
}
