//
//  LanguageEntry.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/31/22.
//

import Foundation
@preconcurrency import SwiftUI

@frozen public struct LanguageEntry: Identifiable, Hashable, Sendable {
  public let id = UUID()
  public var title: String
  public var icon: String
  public var iconColor: Color?
  public var iconWidth: CGFloat = 16
  public var iconHeight: CGFloat = 16
  public var fileExtension: String
}

let languages: [LanguageEntry] = [
  .init(title: "Python", icon: "python", iconColor: .yellow, fileExtension: "py"),
  .init(title: "JavaScript", icon: "javascript", iconColor: .yellow, fileExtension: "js"),
  // Golang's logo has a 2:1 ratio, not 1:1 like everyone else
  .init(title: "Golang", icon: "go", iconColor: Color(fromHex: "#00ADD8")!, iconWidth: 32, iconHeight: 16,
        fileExtension: "go"),
  .init(title: "Java", icon: "java", iconColor: .red, fileExtension: "java"),
  .init(title: "ANSI C", icon: "c", iconColor: .blue, fileExtension: "c"),
  .init(title: "C++", icon: "cpp", iconColor: .blue, fileExtension: "cpp"),
  .init(title: "C#", icon: "csharp", iconColor: .purple, fileExtension: "cs"),
  .init(title: "Ruby", icon: "ruby", iconColor: .red, fileExtension: "rb"),
  .init(title: "Kotlin", icon: "kotlin", fileExtension: "kt"),
  .init(title: "Swift", icon: "swift", iconColor: .orange, fileExtension: "swift")
]
