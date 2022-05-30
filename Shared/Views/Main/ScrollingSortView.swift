//
//  ScrollingSortView.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import SwiftUI
import MarkdownUI

struct ComplexityEntry: Identifiable {
    let id = UUID()
    var name: String
    var bigOValue: String
}

struct ScrollingSortView: View {
    var algorithm: Algorithms
    var description: String
    var entries: [ComplexityEntry]
    var key: String
    private let codeWidth: CGFloat = 512
    private let codeHeight: CGFloat = 1240
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    SortView(algorithm: algorithm)
                        .frame(width: geo.size.width, height: geo.size.height)
                    Group {
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("Description")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Markdown(description)
                                    .font(.system(size: 16, design: .default))
                                    .lineSpacing(1.75)
                            }.frame(width: 0.6 * geo.size.width, height: nil, alignment: .leading)
                            VStack(spacing: 4) {
                                Text("Complexity")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                // This is a really stupid solution to an artificial limitation: the Table view is only available on macOS in SwiftUI 2.
                                VStack(spacing: 2) {
                                    ForEach(entries) { entry in
                                        HStack(spacing: 1) {
                                            Text("• \(entry.name): ")
                                                .bold()
                                                .font(.system(size: 16, design: .default)) +
                                            Text(entry.bigOValue)
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16, design: .default))
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                }
                            }.frame(width: 0.4 * geo.size.height, height: nil, alignment: .leading)
                        }
                    }.padding(.all, 32)
                    Group {
                        Text("Implementations")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .multilineTextAlignment(.leading)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                VStack(spacing: 4) {
                                    Label {
                                        Text("ANSI C")
                                    } icon: {
                                        Image.ofAsset("c").foregroundColor(.blue)
                                    }.font(.headline)
                                    Text(loadResource(key, "c"))
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: codeWidth, alignment: .topLeading)
                                    Spacer()
                                }
                                VStack(spacing: 4) {
                                    Label {
                                        Text("C++")
                                    } icon: {
                                        Image.ofAsset("cpp").foregroundColor(.blue)
                                    }.font(.headline)
                                    Text(loadResource(key, "cpp"))
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: codeWidth, alignment: .topLeading)
                                    Spacer()
                                }
                                VStack(spacing: 4) {
                                    Label {
                                        Text("Java")
                                    } icon: {
                                        Image.ofAsset("java").foregroundColor(.red)
                                    }.font(.headline)
                                    Text(loadResource(key, "java"))
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: codeWidth, alignment: .topLeading)
                                    Spacer()
                                }
                                VStack(spacing: 4) {
                                    Label {
                                        Text("JavaScript")
                                    } icon: {
                                        Image.ofAsset("javascript").foregroundColor(.yellow)
                                    }.font(.headline)
                                    Text(loadResource(key, "js"))
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: codeWidth, alignment: .topLeading)
                                    Spacer()
                                }
                                VStack(spacing: 4) {
                                    Label {
                                        Text("Python")
                                    } icon: {
                                        Image.ofAsset("python").foregroundColor(.yellow)
                                    }.font(.headline)
                                    Text(loadResource(key, "py"))
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: codeWidth, alignment: .topLeading)
                                    Spacer()
                                }
                            }.frame(minHeight: 512)
                        }
                    }.padding(.all, 32)
                }
            }
        }
    }
}

extension ScrollingSortView {
    func loadResource(_ filename: String, _ ext: String) -> String {
        let data: String
        guard let path = Bundle.main.path(forResource: key, ofType: "bundle"),
              let bundle = Bundle(path: path),
              let url = bundle.path(forResource: filename, ofType: ext) else {
            fatalError("Couldn't find \(filename).\(ext) in main bundle.")
        }
        do {
            data = try String(contentsOfFile: String(url))
        } catch {
            fatalError("Couldn't load \(filename).\(ext) from main bundle:\n\(error)")
        }
        return data
    }
}
