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
    var description: String
    var averageComplexity: String
    var bestCase: String
    var worstCase: String
    var spaceComplexity: String
    private let metaPadding: CGFloat = CGFloat(32)
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 4) {
                    // TODO: File a Radar issue. I have to add -2x padding to this item if I use padding *anywhere else* within the view. Even if I don't apply padding to this, it magically inherits the padding of everything else.
                    SortView(algorithm: algorithm)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .padding(.leading, metaPadding * -2)
                    Group {
                        Markdown("""
                        ## Description
                        
                        \(description)
                        
                        ## Complexity
                        
                        * **Average Complexity:** \(averageComplexity)
                        * **Best Case:** \(bestCase)
                        * **Worst Case:** \(worstCase)
                        * **Space Complexity:** \(spaceComplexity)
                        """)
                            .markdownStyle(MarkdownStyle(font: .system(size: 16)))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(1.75)
                    }.padding(.all, metaPadding)
                }
            }
        }
    }
}
