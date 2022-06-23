//
//  AttributedCodeView.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/23/22.
//
import SwiftUI

fileprivate let bgColor = Color(fromHex: "#272822")!
fileprivate let text = Color(fromHex: "#F8F8F2")!
fileprivate let baseColor = text
fileprivate let error = Color(fromHex: "#960050")!
fileprivate let comment = Color(fromHex: "#75715E")!
fileprivate let keyword = Color(fromHex: "#66D9EF")!
fileprivate let `operator` = Color(fromHex: "#F92672")!
fileprivate let punctuation = Color(fromHex: "#F8F8F2")!
fileprivate let name = Color(fromHex: "#A6E22E")!
fileprivate let number = Color(fromHex: "#AE81FF")!
fileprivate let string = Color(fromHex: "#E6DB74")!

struct AttributedCode: View {
  private var attributedString: AttributedString
  private let font: Font = .system(size: 12, weight: .regular, design: .monospaced)
  private static let colors: [CodeAttributes.Value: Color] = [
    .text: text,
    .whitespace: baseColor,
    .error: error,
    .other: baseColor,
    .comment: comment,
    .commentMultiline: comment,
    .commentPreproc: comment,
    .commentSingle: comment,
    .commentSpecial: comment,
    .commentHashbang: comment,
    .commentPreprocFile: comment,
    .keyword: keyword,
    .keywordConstant: keyword,
    .keywordDeclaration: keyword,
    .keywordNamespace: keyword,
    .keywordPseudo: keyword,
    .keywordReserved: keyword,
    .keywordType: keyword,
    .operator: `operator`,
    .operatorWord: `operator`,
    .punctuation: punctuation,
    .name: punctuation,
    .nameAttribute: name,
    .nameBuiltin: baseColor,
    .nameBuiltinPseudo: baseColor,
    .nameClass: name,
    .nameConstant: keyword,
    .nameDecorator: name,
    .nameEntity: baseColor,
    .nameException: name,
    .nameFunction: name,
    .nameProperty: baseColor,
    .nameLabel: baseColor,
    .nameNamespace: baseColor,
    .nameOther: baseColor,
    .nameTag: `operator`,
    .nameVariable: baseColor,
    .nameVariableClass: baseColor,
    .nameVariableGlobal: baseColor,
    .nameVariableInstance: baseColor,
    .number: number,
    .numberFloat: number,
    .numberHex: number,
    .numberInteger: number,
    .numberIntegerLong: number,
    .numberOct: number,
    .literal: number,
    .literalDate: string,
    .string: string,
    .stringBacktick: string,
    .stringChar: string,
    .stringDoc: string,
    .stringDouble: string,
    .stringEscape: number,
    .stringHeredoc: string,
    .stringInterpol: string,
    .stringOther: string,
    .stringRegex: string,
    .stringSingle: string,
    .stringSymbol: string,
    .generic: baseColor,
    .genericDeleted: `operator`,
    .genericEmph: baseColor,
    .genericError: baseColor,
    .genericHeading: baseColor,
    .genericInserted: name,
    .genericOutput: baseColor,
    .genericPrompt: baseColor,
    .genericStrong: baseColor,
    .genericSubheading: comment,
    .genericTraceback: baseColor
  ]

  
  var body: some View {
    Text(attributedString)
      .font(font)
      .padding()
      .fixedSize(horizontal: true, vertical: true)
      .background(bgColor)
      .cornerRadius(15)
  }
  
  init(_ key: String) {
    attributedString = AttributedCode.annotateCode(
      from: AttributedString(localized: String.LocalizationValue(key), including: \.sortVisualizerApp))
  }
  
  private static func annotateCode(from source: AttributedString) -> AttributedString {
    var attrString = source
    for run in attrString.runs {
      guard let codeMode = run.code else {
        continue
      }
      let color = colors[codeMode]!
      var container = AttributeContainer()
      container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = color
      attrString[run.range].mergeAttributes(container)
    }
    return attrString
  }
}

enum CodeAttributes: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
  enum Value: String, Codable, Hashable {
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
  
  static var name = "code"
}

extension AttributeScopes {
  struct SortVisualizerAttributes: AttributeScope {
    let code: CodeAttributes
  }
  
  var sortVisualizerApp: SortVisualizerAttributes.Type { SortVisualizerAttributes.self }
}

extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.SortVisualizerAttributes, T>) -> T {
    self[T.self]
  }
}

struct AttributedCode_Previews: PreviewProvider {
  static var previews: some View {
    AttributedCode("^[// Testing, testing, 123.](code: 'Token.Comment.Preproc')")
  }
}
