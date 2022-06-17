//
//  ScrollingSortView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI
import MarkdownUI

struct LanguageView: View {
  var algorithm: Algorithms
  var language: LanguageEntry
  
  var body: some View {
    VStack(alignment: .center, spacing: 4) {
      Label {
        Text(language.title)
      } icon: {
        if let iconColor = language.iconColor {
          Image.ofAsset(language.icon, width: CGFloat(language.iconWidth), height: CGFloat(language.iconHeight))
            .foregroundColor(iconColor)
        } else {
          Image.ofAsset(language.icon, width: CGFloat(language.iconWidth), height: CGFloat( language.iconHeight))
        }
      }.font(.headline)
      CodeView(tokens: loadHighlightResource(algorithm, language.fileExtension))
        .frame(alignment: .center)
    }
  }
}

struct ScrollingSortView: View {
  var algorithm: Algorithms
  
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
              }.frame(maxWidth: 0.75 * geo.size.width)
              VStack(alignment: .center, spacing: 16) {
                Text("Complexity")
                  .font(.system(size: 24, weight: .bold, design: .default))
                  .multilineTextAlignment(.leading)
                VStack(spacing: 2) {
                  ForEach(loadComplexityResource(algorithm)) { entry in
                    HStack(spacing: 1) {
                      Text("• \(entry.key): ")
                        .bold()
                        .font(.system(size: 16, design: .default)) +
                      Text(entry.value)
                        .foregroundColor(.blue)
                        .font(.system(size: 16, design: .default))
                      Spacer()
                    }
                  }
                  Spacer()
                }
              }.frame(maxWidth: 0.25 * geo.size.width)
            }
          }.padding(.all, 32)
          Group {
            Text("Implementations")
              .font(.system(size: 24, weight: .bold, design: .default))
              .multilineTextAlignment(.leading)
            #if targetEnvironment(macCatalyst)
            // Manually spaced grid. LazyVGrid was causing a top of performance issues.
            VStack(alignment: .leading, spacing: 16) {
              ForEach(0..<5) { i in
                HStack(alignment: .top, spacing: 16) {
                  // This is a really weird way to remove extra complexity.
                  // The first ForEach is [0, 1, 2, 3, 4]. This converts it to [[0, 2], [2, 4], [4, 6], [6, 8], [8, 10]].
                  ForEach(languages[(i * 2)..<((i * 2) + 2)]) { language in
                    LanguageView(algorithm: algorithm, language: language)
                      .frame(width: geo.size.width * 0.45, height: nil, alignment: .center)
                  }
                }
              }
            }
            #elseif os(iOS)
            // This was added after testing on an iPad. It's not a bad experience per se, but it's a better experience than having multiple code views stuck on top of one another.
            VStack(alignment: .leading, spacing: 8) {
              ForEach(languages) { language in
                LanguageView(algorithm: algorithm, language: language)
              }
            }
            #endif
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
  var result: [ComplexityEntry] = []
  guard let path = Bundle.main.path(forResource: key, ofType: "bundle"),
        let bundle = Bundle(path: path),
        let url = bundle.path(forResource: "complexity", ofType: "json") else {
    fatalError("Couldn't find complexity.json in \(key).bundle!")
  }
  let data = try! Data(contentsOf: URL(fileURLWithPath: url))
  if let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    guard let items = json["complexities"] as? [[String: String]] else {
      return result
    }
    for item in items {
      guard let key = item["key"],
            let value = item["value"] else {
        continue
      }
      result.append(ComplexityEntry(key: key, value: value))
    }
  }
  return result
}

func loadHighlightResource(_ algorithm: Algorithms, _ ext: String) -> [Token] {
  let key = algorithm.rawValue
  var result: [Token] = []
  guard let path = Bundle.main.path(forResource: key, ofType: "bundle"),
        let bundle = Bundle(path: path),
        let url = bundle.path(forResource: key, ofType: "\(ext).json") else {
    fatalError("Couldn't find \(key).\(ext).json in \(key).bundle!")
  }
  let data = try! Data(contentsOf: URL(fileURLWithPath: url))
  if let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    guard let items = json["result"] as? [[String: String]] else {
      return result
    }
    for item in items {
      guard let rawType = item["type"],
            let value = item["value"] else {
        continue
      }
      result.append(Token(type: .fromRaw(rawType), value: value))
    }
  }
  return result
}
