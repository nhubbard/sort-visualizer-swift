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
    private let implementationGrid: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    SortView(algorithm: algorithm)
                        .frame(width: geo.size.width, height: geo.size.height)
                    Group {
                        LazyVGrid(columns: [.init(.fixed(0.6 * geo.size.width)), .init(.fixed(0.4 * geo.size.width))]) {
                            Text("Description")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .multilineTextAlignment(.leading)
                            Text("Complexity")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .multilineTextAlignment(.leading)
                            Markdown(loadResource("description", "md"))
                                .font(.system(size: 16, design: .default))
                                .lineSpacing(1.75)
                            VStack(spacing: 2) {
                                ForEach(loadComplexityResource()) { entry in
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
                        }
                    }.padding(.all, 32)
                    Group {
                        Text("Implementations")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .multilineTextAlignment(.leading)
                        LazyVGrid(columns: implementationGrid) {
                            ForEach(languages) { language in
                                VStack(spacing: 4) {
                                    Label {
                                        Text(language.title)
                                    } icon: {
                                        if language.iconColor != nil {
                                            Image.ofAsset(language.icon, width: CGFloat(language.iconWidth), height: CGFloat(language.iconHeight))
                                                .foregroundColor(language.iconColor!)
                                        } else {
                                            Image.ofAsset(language.icon, width: CGFloat(language.iconWidth), height: CGFloat( language.iconHeight))
                                        }
                                    }.font(.headline)
                                    CodeView(tokens: loadHighlightResource(language.fileExtension))
                                }
                            }
                        }
                    }.padding(.all, 32)
                }
            }
        }
    }
}

extension ScrollingSortView {
    func loadResource(_ filename: String, _ ext: String) -> String {
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
    
    func loadComplexityResource() -> [ComplexityEntry] {
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
    
    func loadHighlightResource(_ ext: String) -> [Token] {
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
}
