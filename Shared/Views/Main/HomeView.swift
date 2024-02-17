//
//  HomeView.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/26/22.
//

import SwiftUI
import MarkdownUI

@frozen public struct HomeView: View {
  public var body: some View {
    ScrollView {
      VStack(spacing: 2) {
        Text(String(localized: "Welcome to")).bold()
        RandomizingHeader(text: String(localized: "SORT SYMPHONY"))
        Markdown {
          String(localized: "home_copy")
        }
        .markdownTextStyle {
          FontFamilyVariant(.normal)
          FontFamily(.system())
          FontSize(.em(1))
        }
        .lineSpacing(1.75)
        .padding()
      }
      .navigationTitle(String(localized: "Home"))
    }.padding()
  }
}

#Preview {
  HomeView()
    .frame(minWidth: 900, minHeight: 600)
}
