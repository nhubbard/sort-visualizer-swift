//
//  PygmentsTheme.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

// Colors based on CSS class names.
// Background color
fileprivate let hl = Color(fromHex: "#F8F8F8")!
// Comment, Comment.{Hashbang,Multiline,PreprocFile,Single,Special}
fileprivate let c = Color(fromHex: "#3D7B7B")!
// Error
fileprivate let err = Color(fromHex: "#FF0000")!
// Keyword{,.Constant,.Declaration,.Namespace,.Reserved,.Pseudo}, Name.{Tag,Builtin,Builtin.Pseudo}, and Literal.String.Other
fileprivate let k = Color(fromHex: "#008000")!
// Operator, Number{,.Bin,.Float,.Hex,.Integer,.Oct,.Integer.Long}
fileprivate let o = Color(fromHex: "#666666")!
// Comment.Preproc
fileprivate let cp = Color(fromHex: "#9C6500")!
// Generic.Deleted
fileprivate let gd = Color(fromHex: "#A00000")!
// Generic.Error
fileprivate let gr = Color(fromHex: "#E40000")!
// Generic.{Heading,Prompt}
fileprivate let gh = Color(fromHex: "#000080")!
// Generic.Inserted
fileprivate let gi = Color(fromHex: "#008400")!
// Generic.Output and Name.Entity
fileprivate let go = Color(fromHex: "#717171")!
// Generic.Subheading
fileprivate let gu = Color(fromHex: "#800080")!
// Generic.Traceback
fileprivate let gt = Color(fromHex: "#0044DD")!
// Keyword.Type
fileprivate let kt = Color(fromHex: "#B00040")!
// String{,.Affix,.Backtick,.Char,.Delimiter,.Double,.Heredoc,.Single}; Literal.String.Doc
fileprivate let s = Color(fromHex: "#BA2121")!
// Name.Attribute
fileprivate let na = Color(fromHex: "#687822")!
// Name.{Class,Function,Namespace,Function.Magic}
fileprivate let nc = Color(fromHex: "#0000FF")!
// Name.Constant
fileprivate let no = Color(fromHex: "#880000")!
// Name.Decorator, Operator.Word
fileprivate let nd = Color(fromHex: "#AA22FF")!
// Name.Exception
fileprivate let ne = Color(fromHex: "#CB3F38")!
// Name.Label
fileprivate let nl = Color(fromHex: "#767600")!
// Name.Variable{,.Class,.Global,.Instance,.Magic}; String.Symbol
fileprivate let nv = Color(fromHex: "#19177C")!
// Text.Whitespace
fileprivate let w = Color(fromHex: "#BBBBBB")!
// String.Escape
fileprivate let se = Color(fromHex: "#AA5D1F")!
// String.{Interpol,Regex}
fileprivate let si = Color(fromHex: "#A45A77")!

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
        case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDouble, .stringHeredoc, .stringSingle:
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
        case .nameVariable, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic, .stringSymbol:
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
