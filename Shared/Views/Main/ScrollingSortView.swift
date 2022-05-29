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
                }
            }
        }
    }
}
