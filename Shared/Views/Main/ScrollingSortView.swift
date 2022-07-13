//
//  ScrollingSortView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI
import MarkdownUI

fileprivate let adaptiveWidthValue: CGFloat = CGFloat(0.465)

struct LanguageView: View {
  var algorithm: Algorithms
  var language: LanguageEntry
  
  var body: some View {
    VStack(alignment: .center, spacing: 4) {
      Label {
        Text(language.title)
      } icon: {
        Image.ofAsset(language.icon, width: CGFloat(language.iconWidth), height: CGFloat(language.iconHeight))
          .foregroundColor(language.iconColor ?? .white)
      }.font(.headline)
      AttributedCode(loadHighlightResource(algorithm, language.fileExtension))
    }
  }
}

struct ScrollingSortView: View {
  var algorithm: Algorithms
  @State private var selectedLanguage: Int = 0
  
  var body: some View {
    GeometryReader { geo in
      ScrollView {
        VStack(alignment: .leading, spacing: 4) {
          SortView(algorithm: algorithm)
            .frame(width: geo.size.width, height: geo.size.height)
          Group {
            HStack(alignment: .top, spacing: 16) {
              VStack(alignment: .center, spacing: 16) {
                Text("Description")
                  .font(.system(size: 24, weight: .bold, design: .default))
                  .multilineTextAlignment(.leading)
                Markdown(loadResource(algorithm, "description", "md"))
                  .font(.system(size: 16, design: .default))
                  .lineSpacing(1.75)
              }.frame(maxWidth: 0.65 * geo.size.width)
              VStack(alignment: .center, spacing: 16) {
                Text("Complexity")
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
                          Text("• \(entry.key): ")
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
          Group {
            HStack {
              Text("Implementations")
                .font(.system(size: 24, weight: .bold, design: .default))
                .multilineTextAlignment(.leading)
              HStack(alignment: .center, spacing: 0) {
                ForEach(0..<languages.count, id: \.self) { i in
                  HStack {
                    Label {
                      Text(languages[i].title)
                    } icon: {
                      Image.ofAsset(
                        languages[i].icon,
                        width: CGFloat(languages[i].iconWidth),
                        height: CGFloat(languages[i].iconHeight)
                      )
                      .foregroundColor(languages[i].iconColor ?? .primary)
                    }
                  }
                  .padding(.all, 10)
                  .background(
                    Capsule()
                      .fill(.primary)
                      .opacity(self.selectedLanguage == i ? 0.24 : 0)
                  )
                  .onTapGesture { self.selectedLanguage = i }
                }
              }
              .frame(alignment: .center)
              .padding(.all, 3)
              .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            AttributedCode(loadHighlightResource(algorithm, languages[self.selectedLanguage].fileExtension))
            /*
            VStack(alignment: .center, spacing: 4) {
              Picker(selection: $selectedLanguage, label: Text("Select Programming Language")) {
                ForEach(0..<languages.count, id: \.self) { i in
                  Label {
                    Text(languages[i].title)
                  } icon: {
                    Image.ofAsset(languages[i].icon, width: CGFloat(languages[i].iconWidth), height: CGFloat(languages[i].iconHeight))
                      .foregroundColor(languages[i].iconColor ?? .white)
                  }.font(.headline)
                }
              }.pickerStyle(SegmentedPickerStyle())
              AttributedCode(loadHighlightResource(algorithm, languages[selectedLanguage].fileExtension))
            }*/
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
    data = try String(contentsOfFile: String(url))
  } catch {
    fatalError("Couldn't load \(filename).\(ext) from \(key).bundle:\n\(error)")
  }
  return data
}

func loadComplexityResource(_ algorithm: Algorithms) -> [ComplexityEntry] {
  let key = algorithm.rawValue
  guard let path = Bundle.main.path(forResource: key, ofType: "bundle"),
        let bundle = Bundle(path: path),
        let url = bundle.path(forResource: "complexity", ofType: "json") else {
    fatalError("Couldn't find complexity.json in \(key).bundle!")
  }
  let data = try! Data(contentsOf: URL(fileURLWithPath: url))
  let decoder = JSONDecoder()
  guard let contents = try? decoder.decode(ComplexityFile.self, from: data) else {
    return []
  }
  return contents.complexities
}

func loadHighlightResource(_ algorithm: Algorithms, _ ext: String) -> String {
  let key = algorithm.rawValue
  let data: String
  guard let path = Bundle.main.path(forResource: key, ofType: "bundle"),
        let bundle = Bundle(path: path),
        let url = bundle.path(forResource: key, ofType: "\(ext).md") else {
    fatalError("Couldn't find \(key).\(ext).md in \(key).bundle!")
  }
  do {
    data = try String(contentsOfFile: String(url))
  } catch {
    fatalError("Couldn't load \(algorithm.rawValue).\(ext).md from \(key).bundle:\n\(error)")
  }
  return data
}
