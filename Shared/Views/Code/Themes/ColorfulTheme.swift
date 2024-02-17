//
//  ColorfulTheme.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

@frozen public struct ColorfulTheme: CodeTheme {
  func getBgColor() -> Color { .white }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: .white).then { it in
      switch token {
        case .comment, .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .genericOutput:
          it.fg("#888888")
        case .genericError:
          it.fg("#ff0000")
        case .error:
          it.fg("#ff0000").bg("#ffaaaa")
        case .nameException:
          it.fg("#ff0000").bold()
        case .keywordConstant, .keywordDeclaration, .keywordNamespace, .keyword, .keywordReserved:
          it.fg("#008800").bold()
        case .operator:
          it.fg("#333333")
        case .commentPreproc:
          it.fg("#557799")
        case .commentSpecial:
          it.fg("#cc0000").bold()
        case .genericDeleted:
          it.fg("#a00000")
        case .genericEmph:
          it.italic()
        case .genericHeading:
          it.fg("#000080").bold()
        case .genericInserted:
          it.fg("#00a000")
        case .genericPrompt:
          it.fg("#c65d09").bold()
        case .genericStrong:
          it.bold()
        case .genericSubheading:
          it.fg("#800080").bold()
        case .genericTraceback, .stringChar:
          it.fg("#0044dd")
        case .keywordPseudo:
          it.fg("#003388").bold()
        case .keywordType:
          it.fg("#333399").bold()
        case .number, .numberBin, .numberFloat:
          it.fg("#6600ee").bold()
        case .string, .stringAffix, .stringBacktick, .stringDelimiter, .stringDouble, .stringHeredoc, .stringSingle:
          it.bg("#fff0f0").fg(.black)
        case .nameAttribute:
          it.fg("#0000cc")
        case .nameBuiltin, .nameBuiltinPseudo:
          it.fg("#007020")
        case .nameClass:
          it.fg("#bb0066").bold()
        case .nameConstant:
          it.fg("#003366").bold()
        case .nameDecorator:
          it.fg("#555555").bold()
        case .nameEntity:
          it.fg("#880000").bold()
        case .nameFunction, .nameFunctionMagic:
          it.fg("#0066bb").bold()
        case .nameLabel:
          it.fg("#997700").bold()
        case .nameNamespace:
          it.fg("#0e84b5").bold()
        case .nameTag:
          it.fg("#007700")
        case .nameVariable, .nameVariableMagic:
          it.fg("#996633")
        case .operatorWord:
          it.fg("#000000").bold()
        case .whitespace:
          it.fg("#bbbbbb")
        case .numberHex:
          it.fg("#005588").bold()
        case .numberInteger, .numberIntegerLong:
          it.fg("#0000dd").bold()
        case .numberOct:
          it.fg("#4400ee").bold()
        case .stringDoc:
          it.fg("#dd4422")
        case .stringEscape:
          it.fg("#666666").bg("#fff0f0").bold()
        case .stringInterpol:
          it.bg("#eeeeee").fg(.black)
        case .stringOther:
          it.fg("#dd2200").bg("#fff0f0")
        case .stringRegex:
          it.fg("#000000").bg("#fff0ff")
        case .stringSymbol:
          it.fg("#aa6600")
        case .nameVariableClass:
          it.fg("#336699")
        case .nameVariableGlobal:
          it.fg("#dd7700").bold()
        case .nameVariableInstance:
          it.fg("#3333bb")
        default:
          it.fg(.black)
      }
    }.build()
  }
}
