//
//  PygmentsTheme.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

// Colors based on CSS class names.
// Background color
private let hl = Color(fromHex: "#F8F8F8")!
// Comment, Comment.{Hashbang,Multiline,PreprocFile,Single,Special}
private let c = Color(fromHex: "#3D7B7B")!
// Error
private let err = Color(fromHex: "#FF0000")!
// Keyword{,.Constant,.Declaration,.Namespace,.Reserved,.Pseudo}, Name.{Tag,Builtin,Builtin.Pseudo},
// Literal.String.Other
private let k = Color(fromHex: "#008000")!
// Operator, Number{,.Bin,.Float,.Hex,.Integer,.Oct,.Integer.Long}
private let o = Color(fromHex: "#666666")!
// Comment.Preproc
private let cp = Color(fromHex: "#9C6500")!
// Generic.Deleted
private let gd = Color(fromHex: "#A00000")!
// Generic.Error
private let gr = Color(fromHex: "#E40000")!
// Generic.{Heading,Prompt}
private let gh = Color(fromHex: "#000080")!
// Generic.Inserted
private let gi = Color(fromHex: "#008400")!
// Generic.Output and Name.Entity
private let go = Color(fromHex: "#717171")!
// Generic.Subheading
private let gu = Color(fromHex: "#800080")!
// Generic.Traceback
private let gt = Color(fromHex: "#0044DD")!
// Keyword.Type
private let kt = Color(fromHex: "#B00040")!
// String{,.Affix,.Backtick,.Char,.Delimiter,.Double,.Heredoc,.Single}; Literal.String.Doc
private let s = Color(fromHex: "#BA2121")!
// Name.Attribute
private let na = Color(fromHex: "#687822")!
// Name.{Class,Function,Namespace,Function.Magic}
private let nc = Color(fromHex: "#0000FF")!
// Name.Constant
private let no = Color(fromHex: "#880000")!
// Name.Decorator, Operator.Word
private let nd = Color(fromHex: "#AA22FF")!
// Name.Exception
private let ne = Color(fromHex: "#CB3F38")!
// Name.Label
private let nl = Color(fromHex: "#767600")!
// Name.Variable{,.Class,.Global,.Instance,.Magic}; String.Symbol
private let nv = Color(fromHex: "#19177C")!
// Text.Whitespace
private let w = Color(fromHex: "#BBBBBB")!
// String.Escape
private let se = Color(fromHex: "#AA5D1F")!
// String.{Interpol,Regex}
private let si = Color(fromHex: "#A45A77")!

@frozen public struct PygmentsTheme: CodeTheme {
  func getBgColor() -> Color { hl }
  func getFormat(token: CodeAttributes.Value) -> TextFormat {
    TextFormat.getBuilder(bg: hl).then { it in
      switch token {
        case .comment:
          it.fg(c).italic()
        case .error:
          it.bg(err)
        case .keyword:
          it.fg(k).bold()
        case .operator:
          it.fg(o)
        case .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .commentSpecial:
          it.fg(c).italic()
        case .commentPreproc:
          it.fg(cp)
        case .genericDeleted:
          it.fg(gd)
        case .genericEmph:
          it.italic()
        case .genericError:
          it.fg(gr)
        case .genericHeading, .genericPrompt:
          it.fg(gh).bold()
        case .genericInserted:
          it.fg(gi)
        case .genericOutput:
          it.fg(go)
        case .nameEntity:
          it.fg(go).bold()
        case .genericStrong:
          it.bold()
        case .genericSubheading:
          it.fg(gu).bold()
        case .genericTraceback:
          it.fg(gt)
        case .keywordConstant, .keywordDeclaration, .keywordNamespace, .keywordReserved, .nameTag:
          it.fg(k).bold()
        case .keywordPseudo, .nameBuiltin, .stringOther, .nameBuiltinPseudo:
          it.fg(k)
        case .keywordType:
          it.fg(kt)
        case .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
          it.fg(o)
        case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDouble, .stringHeredoc,
             .stringSingle:
          it.fg(s)
        case .nameAttribute:
          it.fg(na)
        case .nameFunction, .nameFunctionMagic:
          it.fg(nc)
        case .nameClass, .nameNamespace:
          it.fg(nc).bold()
        case .nameConstant:
          it.fg(no)
        case .nameDecorator:
          it.fg(nd)
        case .operatorWord:
          it.fg(nd).bold()
        case .nameException:
          it.fg(ne).bold()
        case .nameLabel:
          it.fg(nl)
        case .nameVariable, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic,
             .stringSymbol:
          it.fg(nv)
        case .whitespace:
          it.fg(w)
        case .stringDoc:
          it.fg(s).italic()
        case .stringEscape:
          it.fg(se).bold()
        case .stringRegex:
          it.fg(si)
        case .stringInterpol:
          it.fg(si).bold()
        default:
          it.fg(.black)
      }
    }.build()
  }
}
