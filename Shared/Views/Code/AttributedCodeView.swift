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

#Preview {
  AttributedCode("^[// Testing, testing, 123.](code: 'Token.Comment.Preproc')")
}
