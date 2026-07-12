/// Simplified from `Legacy/Shared/Data/Primary/LanguageEntry.swift` — just `title`/file-extension
/// pairs, no per-language logo asset (no icon asset catalog was ported into v2; the language
/// picker renders as plain text, not icon buttons).
public struct CodeLanguage: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

extension CodeLanguage {
    public static let all: [CodeLanguage] = [
        CodeLanguage(id: "py", title: "Python"),
        CodeLanguage(id: "js", title: "JavaScript"),
        CodeLanguage(id: "go", title: "Go"),
        CodeLanguage(id: "java", title: "Java"),
        CodeLanguage(id: "c", title: "C"),
        CodeLanguage(id: "cpp", title: "C++"),
        CodeLanguage(id: "cs", title: "C#"),
        CodeLanguage(id: "rb", title: "Ruby"),
        CodeLanguage(id: "kt", title: "Kotlin"),
        CodeLanguage(id: "swift", title: "Swift")
    ]
}
