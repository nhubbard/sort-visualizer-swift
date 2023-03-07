//
//  EmacsTheme.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

@frozen public struct EmacsTheme: CodeTheme {
  func getBgColor() -> Color { Color(fromHex: "#f8f8f8")! }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: getBgColor()).then { it in
      switch token {
        case .commentPreproc:
          it.fg("#080")
        case .commentSpecial:
          it.fg("#080").bold()
        case .comment, .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle:
          it.fg("#080").italic()
        case .error:
          it.fg("#fff").bg("#f00")
        case .keywordPseudo:
          it.fg("#a2f")
        case .keywordConstant, .keywordDeclaration, .keywordNamespace, .keyword, .keywordReserved:
          it.fg("#a2f").bold()
        case .number, .operator, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
          it.fg("#666")
        case .genericDeleted:
          it.fg("#a00000")
        case .genericEmph:
          it.italic()
        case .genericError:
          it.fg("#f00")
        case .genericHeading, .genericPrompt:
          it.fg("#000080").bold()
        case .genericInserted, .nameFunction, .nameFunctionMagic:
          it.fg("#00a000")
        case .genericOutput:
          it.fg("#888")
        case .genericStrong:
          it.bold()
        case .genericSubheading:
          it.fg("#800080").bold()
        case .genericTraceback:
          it.fg("#04d")
        case .keywordType:
          it.fg("#0b0").bold()
        case .string, .nameAttribute, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDouble,
             .stringHeredoc, .stringSingle:
          it.fg("#b44")
        case .stringDoc:
          it.fg("#b44").italic()
        case .nameBuiltin, .nameDecorator, .nameBuiltinPseudo:
          it.fg("#a2f")
        case .operatorWord:
          it.fg("#a2f").bold()
        case .nameClass:
          it.fg("#00f")
        case .nameNamespace:
          it.fg("#00f").bold()
        case .nameConstant:
          it.fg("#800")
        case .nameEntity:
          it.fg("#999").bold()
        case .nameException:
          it.fg("#d2413a").bold()
        case .nameLabel:
          it.fg("#a0a000")
        case .stringOther:
          it.fg("#008000")
        case .nameTag:
          it.fg("#008000").bold()
        case .nameVariable:
          it.fg("#b8860b")
        case .whitespace:
          it.fg("#bbb")
        case .stringEscape:
          it.fg("#b62").bold()
        case .stringRegex:
          it.fg("#b68")
        case .stringInterpol:
          it.fg("#b68").bold()
        case .stringSymbol, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic:
          it.fg("#b8860b")
        default:
          it.fg(.black).bg(getBgColor())
      }
    }.build()
  }
}
