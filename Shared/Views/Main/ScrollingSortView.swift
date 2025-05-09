//
//  ScrollingSortView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI
import MarkdownUI

struct ScrollingSortView: View {
  var algorithm: Algorithms
  @State private var selectedLanguage: LanguageEntry = languages[0]

  var body: some View {
    GeometryReader { geo in
      ScrollView {
        VStack(alignment: .leading, spacing: 4) {
          SortView(algorithm: algorithm)
            .frame(width: geo.size.width, height: geo.size.height)
          Group {
            HStack(alignment: .top, spacing: 16) {
              // Description
              VStack(alignment: .center, spacing: 16) {
                Text(String(localized: "Description"))
                  .font(.system(size: 24, weight: .bold, design: .default))
                  .multilineTextAlignment(.leading)
                Markdown(loadResource(algorithm, "description", "md"))
                  .font(.system(size: 16, design: .default))
                  .lineSpacing(1.75)
              }.frame(maxWidth: 0.65 * geo.size.width)
              // Complexity
              VStack(alignment: .center, spacing: 16) {
                Text(String(localized: "Complexity"))
                  .font(.system(size: 24, weight: .bold, design: .default))
                  .multilineTextAlignment(.leading)
                VStack(spacing: 2) {
                  ForEach(loadComplexityResource(algorithm)) { entry in
                    HStack(alignment: .center, spacing: 1) {
                        Group {
                        if entry.mathml != "" {
                          MathView(text: entry.key, unicode: entry.value, math: entry.mathml)
                            .frame(width: nil, height: 36)
                        } else {
                          Text("• \(NSLocalizedString(entry.key, comment: "")): ")
                            .bold()
                            .font(.system(size: 16, design: .default)) +
                          Text(entry.value)
                            .foregroundColor(.blue)
                            .font(.system(size: 16, design: .default))
                        }
                      }
                      Spacer()
                    }
                  }
                  Spacer()
                }
              }.frame(maxWidth: 0.35 * geo.size.width)
            }
          }.padding(.all, 32)
          VStack(alignment: .center, spacing: 8) {
            Text(String(localized: "Implementations"))
              .font(.system(size: 24, weight: .bold, design: .default))
              .multilineTextAlignment(.leading)
            Picker("Language", selection: $selectedLanguage) {
              ForEach(languages, id: \.self) { language in
                Text(language.title)
              }
            }.pickerStyle(.palette)
            AttributedCode(loadHighlightResource(algorithm, selectedLanguage.fileExtension))
              .drawingGroup()
          }.padding(.all, 32)
        }
      }
    }
  }
}

func loadResource(_ algorithm: Algorithms, _ filename: String, _ ext: String) -> String {
  let key = algorithm.rawValue
  let data: String
  guard let path = Bundle.main.path(forResource: key, ofType: "bundle"),
        let bundle = Bundle(path: path),
        let url = bundle.path(forResource: filename, ofType: ext) else {
    fatalError("Couldn't find \(filename).\(ext) in \(key).bundle!")
  }
  do {
    data = try String(contentsOfFile: String(url), encoding: .utf8)
  } catch {
    fatalError("Couldn't load \(filename).\(ext) from \(key).bundle:\n\(error)")
  }
  return data
}

func loadHighlightResource(_ algorithm: Algorithms, _ ext: String) -> String {
  loadResource(algorithm, "\(algorithm.rawValue).\(ext)", "md")
}

func loadComplexityResource(_ algorithm: Algorithms) -> [ComplexityEntry] {
  let data = loadResource(algorithm, "complexity", "json").data(using: .utf8)!
  let decoder = JSONDecoder()
  guard let contents = try? decoder.decode(ComplexityFile.self, from: data) else {
    return []
  }
  return contents.complexities
}

#Preview("Quick Sort") {
  ScrollingSortView(algorithm: .quickSort)
}
