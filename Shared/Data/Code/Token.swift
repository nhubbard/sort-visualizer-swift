//
//  Token.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/30/22.
//

import Foundation
import SwiftUI

struct Token: Identifiable {
  enum TokenType: String, CaseIterable {
    case token = "Token"
    case text = "Token.Text"
    case whitespace = "Token.Text.Whitespace"
    case escape = "Token.Escape"
    case error = "Token.Error"
    case other = "Token.Other"
    case keyword = "Token.Keyword"
    case keywordConstant = "Token.Keyword.Constant"
    case keywordDeclaration = "Token.Keyword.Declaration"
    case keywordNamespace = "Token.Keyword.Namespace"
    case keywordPseudo = "Token.Keyword.Pseudo"
    case keywordReserved = "Token.Keyword.Reserved"
    case keywordType = "Token.Keyword.Type"
    case name = "Token.Name"
    case nameAttribute = "Token.Name.Attribute"
    case nameBuiltin = "Token.Name.Builtin"
    case nameBuiltinPseudo = "Token.Name.Builtin.Pseudo"
    case nameClass = "Token.Name.Class"
    case nameConstant = "Token.Name.Constant"
    case nameDecorator = "Token.Name.Decorator"
    case nameEntity = "Token.Name.Entity"
    case nameException = "Token.Name.Exception"
    case nameFunction = "Token.Name.Function"
    case nameProperty = "Token.Name.Property"
    case nameLabel = "Token.Name.Label"
    case nameNamespace = "Token.Name.Namespace"
    case nameOther = "Token.Name.Other"
    case nameTag = "Token.Name.Tag"
    case nameVariable = "Token.Name.Variable"
    case nameVariableClass = "Token.Name.Variable.Class"
    case nameVariableGlobal = "Token.Name.Variable.Global"
    case nameVariableInstance = "Token.Name.Variable.Instance"
    case literal = "Token.Literal"
    case literalDate = "Token.Literal.Date"
    case string = "Token.Literal.String"
    case stringBacktick = "Token.Literal.String.Backtick"
    case stringChar = "Token.Literal.String.Char"
    case stringDoc = "Token.Literal.String.Doc"
    case stringDouble = "Token.Literal.String.Double"
    case stringEscape = "Token.Literal.String.Escape"
    case stringHeredoc = "Token.Literal.String.Heredoc"
    case stringInterpol = "Token.Literal.String.Interpol"
    case stringOther = "Token.Literal.String.Other"
    case stringRegex = "Token.Literal.String.Regex"
    case stringSingle = "Token.Literal.String.Single"
    case stringSymbol = "Token.Literal.String.Symbol"
    case number = "Token.Literal.Number"
    case numberBin = "Token.Literal.Number.Bin"
    case numberFloat = "Token.Literal.Number.Float"
    case numberHex = "Token.Literal.Number.Hex"
    case numberInteger = "Token.Literal.Number.Integer"
    case numberIntegerLong = "Token.Literal.Number.Integer.Long"
    case numberOct = "Token.Literal.Number.Oct"
    case `operator` = "Token.Operator"
    case operatorWord = "Token.Operator.Word"
    case punctuation = "Token.Punctuation"
    case comment = "Token.Comment"
    case commentHashbang = "Token.Comment.Hashbang"
    case commentMultiline = "Token.Comment.Multiline"
    case commentPreproc = "Token.Comment.Preproc"
    case commentPreprocFile = "Token.Comment.PreprocFile"
    case commentSingle = "Token.Comment.Single"
    case commentSpecial = "Token.Comment.Special"
    case generic = "Token.Generic"
    case genericDeleted = "Token.Generic.Deleted"
    case genericEmph = "Token.Generic.Emph"
    case genericError = "Token.Generic.Error"
    case genericHeading = "Token.Generic.Heading"
    case genericInserted = "Token.Generic.Inserted"
    case genericOutput = "Token.Generic.Output"
    case genericPrompt = "Token.Generic.Prompt"
    case genericStrong = "Token.Generic.Strong"
    case genericSubheading = "Token.Generic.Subheading"
    case genericTraceback = "Token.Generic.Traceback"
  }
  let id = UUID()
  var type: TokenType
  var value: String
}

extension Token.TokenType {
  static func fromRaw(_ rawType: String) -> Token.TokenType {
    for type in Token.TokenType.allCases where type.rawType == rawType {
      return type
    }
    return .text
  }

  func color() -> Color {
    colorMap[self] ?? colorMap[Token.TokenType.text]!
  }
}

extension Token {
  init?(json: [String: Any]) {
    guard let type = json["type"] as? String,
          let value = json["value"] as? String else {
      return nil
    }
    self.type = .fromRaw(type)
    self.value = value
  }
}
