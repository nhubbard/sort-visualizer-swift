//
//  AttributedCodeView.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/23/22.
//
import SwiftUI

struct AttributedCode: View {
  let theme: CodeTheme = MonokaiTheme()
  private var attributedString: AttributedString

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
      from: AttributedString(localized: String.LocalizationValue(key), including: \.sortVisualizerApp), theme: theme)
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

struct AttributedCode_Previews: PreviewProvider {
  static var previews: some View {
    AttributedCode("^[// Testing, testing, 123.](code: 'Token.Comment.Preproc')")
  }
}
