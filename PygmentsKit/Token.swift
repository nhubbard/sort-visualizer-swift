//
//  Token.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

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
    case nameFunctionMagic = "Token.Name.Function.Magic"
    case nameProperty = "Token.Name.Property"
    case nameLabel = "Token.Name.Label"
    case nameNamespace = "Token.Name.Namespace"
    case nameOther = "Token.Name.Other"
    case nameTag = "Token.Name.Tag"
    case nameVariable = "Token.Name.Variable"
    case nameVariableClass = "Token.Name.Variable.Class"
    case nameVariableGlobal = "Token.Name.Variable.Global"
    case nameVariableInstance = "Token.Name.Variable.Instance"
    case nameVariableMagic = "Token.Name.Variable.Magic"
    case literal = "Token.Literal"
    case literalDate = "Token.Literal.Date"
    case string = "Token.Literal.String"
    case stringAffix = "Token.Literal.String.Affix"
    case stringBacktick = "Token.Literal.String.Backtick"
    case stringChar = "Token.Literal.String.Char"
    case stringDelimiter = "Token.Literal.String.Delimiter"
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
    
    var classNames: [TokenType: String] = [
      .token: "",
      // Artificial separator. Please ignore.
      .text: "",
      .whitespace: "w",
      .escape: "esc",
      .error: "err",
      .other: "x",
      // Artificial separator. Please ignore.
      .keyword: "k",
      .keywordConstant: "kc",
      .keywordDeclaration: "kd",
      .keywordNamespace: "kn",
      .keywordPseudo: "kp",
      .keywordReserved: "kr",
      .keywordType: "kt",
      // Artificial separator. Please ignore.
      .name: "n",
      .nameAttribute: "na",
      .nameBuiltin: "nb",
      .nameBuiltinPseudo: "bp",
      .nameClass: "nc",
      .nameConstant: "no",
      .nameDecorator: "nd",
      .nameEntity: "ni",
      .nameException: "ne",
      .nameFunction: "nf",
      .nameFunctionMagic: "fm",
      .nameProperty: "py",
      .nameLabel: "nl",
      .nameNamespace: "nn",
      .nameOther: "nx",
      .nameTag: "nt",
      .nameVariable: "nv",
      .nameVariableClass: "vc",
      .nameVariableGlobal: "vg",
      .nameVariableInstance: "vi",
      .nameVariableMagic: "vm",
      // Artifical separator. Please ignore.
      .literal: "l",
      .literalDate: "ld",
      // Artifical separator. Please ignore.
      .string: "s",
      .stringAffix: "sa",
      .stringBacktick: "sb",
      .stringChar: "sc",
      .stringDelimiter: "dl",
      .stringDoc: "sd",
      .stringDouble: "s2",
      .stringEscape: "se",
      .stringHeredoc: "sh",
      .stringInterpol: "si",
      .stringOther: "sx",
      .stringRegex: "sr",
      .stringSingle: "s1",
      .stringSymbol: "ss",
      // Artifical separator. Please ignore.
      .number: "m",
      .numberBin: "mb",
      .numberFloat: "mf",
      .numberHex: "mh",
      .numberInteger: "mi",
      .numberIntegerLong: "il",
      .numberOct: "mo",
      // Artificial separator. Please ignore.
      .operator: "o",
      .operatorWord: "ow",
      // Artificial separator. Please ignore.
      .punctuation: "p",
      // Artificial separator. Please ignore.
      .comment: "c",
      .commentHashbang: "ch",
      .commentMultiline: "cm",
      .commentPreproc: "cp",
      .commentPreprocFile: "cpf",
      .commentSingle: "c1",
      .commentSpecial: "cs",
      // Artificial separator. Please ignore.
      .generic: "g",
      .genericDeleted: "gd",
      .genericEmph: "ge",
      .genericError: "gr",
      .genericHeading: "gh",
      .genericInserted: "gi",
      .genericOutput: "go",
      .genericPrompt: "gp",
      .genericStrong: "gs",
      .genericSubheading: "gu",
      .genericTraceback: "gt"
    ]
  }
  let id = UUID()
  var type: TokenType
  var value: String
  
  func fromString(value: String) -> TokenType {
    for tokenType in TokenType.allCases {
      if tokenType.rawValue == value {
        return tokenType
      }
    }
    return TokenType.generic
  }
  
  /// Return `true` if `rhs` is a subtype of `lhs`.
  func isSubType(lhs: TokenType, rhs: TokenType) -> Bool {
    return rhs.rawValue.starts(with: lhs.rawValue)
  }
}
