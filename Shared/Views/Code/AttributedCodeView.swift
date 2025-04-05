//
//  AttributedCodeView.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/23/22.
//
import SwiftUI

struct AttributedCode: View {
  // Defaults to CodeThemes.monokai
  @AppStorage("sortCodeViewTheme") var codeThemeId: Int = 0
  var theme: CodeTheme {
    CodeThemes.fromInt(codeThemeId).theme()
  }
  private var attributedString: AttributedString!

  var body: some View {
    Text(attributedString)
      .padding()
      .fixedSize(horizontal: true, vertical: true)
      .background(theme.getBgColor())
      .cornerRadius(15)
      .textSelection(.enabled)
  }

  init(_ key: String) {
    attributedString = AttributedCode.annotateCode(
      from: AttributedString(localized: String.LocalizationValue(key), including: \.sortSymphonyApp), theme: theme)
  }

  private static func annotateCode(from source: AttributedString, theme: CodeTheme) -> AttributedString {
    var attrString = source
    for run in attrString.runs {
      guard let codeMode = run.code else { continue }
      attrString[run.range].mergeAttributes(applyTextFormat(theme.getFormat(token: codeMode)))
    }
    return attrString
  }
}

// swiftlint:disable line_length
#Preview {
  AttributedCode(
#"""
^[#](code: 'Token.Comment.Preproc')^[include](code: 'Token.Comment.Preproc')^[ ](code: 'Token.Text.Whitespace')^[<stdio.h>](code: 'Token.Comment.PreprocFile')
^[#](code: 'Token.Comment.Preproc')^[include](code: 'Token.Comment.Preproc')^[ ](code: 'Token.Text.Whitespace')^[<stdlib.h>](code: 'Token.Comment.PreprocFile')

^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[array](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[16](code: 'Token.Literal.Number.Integer')^[\]](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')^[0](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[39](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[21](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[62](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[91](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[77](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[14](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[23](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')
^[                 ](code: 'Token.Text.Whitespace')^[90](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[69](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[51](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[81](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[68](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[83](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[32](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[56](code: 'Token.Literal.Number.Integer')^[}](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')

^[void](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[swap](code: 'Token.Name.Function')^[(](code: 'Token.Punctuation')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[a](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[b](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[t](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[a](code: 'Token.Name')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[a](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[b](code: 'Token.Name')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[b](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[t](code: 'Token.Name')^[;](code: 'Token.Punctuation')
^[}](code: 'Token.Punctuation')

^[void](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[printList](code: 'Token.Name.Function')^[(](code: 'Token.Punctuation')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[items](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[\]](code: 'Token.Punctuation')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[size](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[for](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[(](code: 'Token.Punctuation')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[0](code: 'Token.Literal.Number.Integer')^[;](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[<](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[size](code: 'Token.Name')^[;](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[+](code: 'Token.Operator')^[+](code: 'Token.Operator')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[if](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[(](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[0](code: 'Token.Literal.Number.Integer')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[      ](code: 'Token.Text.Whitespace')^[printf](code: 'Token.Name')^[(](code: 'Token.Punctuation')^["](code: 'Token.Literal.String')^[\[%d, ](code: 'Token.Literal.String')^["](code: 'Token.Literal.String')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[items](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[}](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[else](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[if](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[(](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[!](code: 'Token.Operator')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[size](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[\-](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[1](code: 'Token.Literal.Number.Integer')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[      ](code: 'Token.Text.Whitespace')^[printf](code: 'Token.Name')^[(](code: 'Token.Punctuation')^["](code: 'Token.Literal.String')^[%d, ](code: 'Token.Literal.String')^["](code: 'Token.Literal.String')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[items](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[}](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[else](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[      ](code: 'Token.Text.Whitespace')^[printf](code: 'Token.Name')^[(](code: 'Token.Punctuation')^["](code: 'Token.Literal.String')^[%d\]](code: 'Token.Literal.String')^["](code: 'Token.Literal.String')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[items](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[}](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[}](code: 'Token.Punctuation')
^[}](code: 'Token.Punctuation')

^[void](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[sort](code: 'Token.Name.Function')^[(](code: 'Token.Punctuation')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[arr](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[\]](code: 'Token.Punctuation')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[j](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[if](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[(](code: 'Token.Punctuation')^[arr](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[j](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[<](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[arr](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[swap](code: 'Token.Name')^[(](code: 'Token.Punctuation')^[&](code: 'Token.Operator')^[arr](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[i](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[&](code: 'Token.Operator')^[arr](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[j](code: 'Token.Name')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[if](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[(](code: 'Token.Punctuation')^[j](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[\-](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[>](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[1](code: 'Token.Literal.Number.Integer')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[t](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[(](code: 'Token.Punctuation')^[j](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[\-](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[+](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[1](code: 'Token.Literal.Number.Integer')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[/](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[3](code: 'Token.Literal.Number.Integer')^[;](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[sort](code: 'Token.Name')^[(](code: 'Token.Punctuation')^[arr](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[j](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[\-](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[t](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[sort](code: 'Token.Name')^[(](code: 'Token.Punctuation')^[arr](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[+](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[t](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[j](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[    ](code: 'Token.Text.Whitespace')^[sort](code: 'Token.Name')^[(](code: 'Token.Punctuation')^[arr](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[i](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[j](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[\-](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[t](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[}](code: 'Token.Punctuation')
^[}](code: 'Token.Punctuation')

^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[main](code: 'Token.Name.Function')^[(](code: 'Token.Punctuation')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[argc](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[char](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[\*](code: 'Token.Operator')^[argv](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[{](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[int](code: 'Token.Keyword.Type')^[ ](code: 'Token.Text.Whitespace')^[size](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[=](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[sizeof](code: 'Token.Keyword')^[(](code: 'Token.Punctuation')^[array](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[/](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[sizeof](code: 'Token.Keyword')^[(](code: 'Token.Punctuation')^[array](code: 'Token.Name')^[\[](code: 'Token.Punctuation')^[0](code: 'Token.Literal.Number.Integer')^[\]](code: 'Token.Punctuation')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[sort](code: 'Token.Name')^[(](code: 'Token.Punctuation')^[array](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[0](code: 'Token.Literal.Number.Integer')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[size](code: 'Token.Name')^[ ](code: 'Token.Text.Whitespace')^[\-](code: 'Token.Operator')^[ ](code: 'Token.Text.Whitespace')^[1](code: 'Token.Literal.Number.Integer')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[printList](code: 'Token.Name')^[(](code: 'Token.Punctuation')^[array](code: 'Token.Name')^[,](code: 'Token.Punctuation')^[ ](code: 'Token.Text.Whitespace')^[size](code: 'Token.Name')^[)](code: 'Token.Punctuation')^[;](code: 'Token.Punctuation')
^[  ](code: 'Token.Text.Whitespace')^[return](code: 'Token.Keyword')^[ ](code: 'Token.Text.Whitespace')^[0](code: 'Token.Literal.Number.Integer')^[;](code: 'Token.Punctuation')
^[}](code: 'Token.Punctuation')
"""#
  )
}
// swiftlint:enable line_length
