import Testing

@testable import SettingsKit

@Suite
struct CodeThemeIDTests {
  @Test
  func knownIDsMapToTheirHandAuthoredDisplayNames() {
    #expect(CodeThemeID(rawValue: "github-dark").displayName == "GitHub Dark")
    #expect(CodeThemeID(rawValue: "one-dark").displayName == "One Dark")
    #expect(CodeThemeID(rawValue: "bw").displayName == "BW")
    #expect(CodeThemeID(rawValue: "vs").displayName == "Visual Studio")
  }

  @Test
  func unknownRawValueFallsBackToCapitalizedRawValue() {
    #expect(CodeThemeID(rawValue: "totally-unknown-theme").displayName == "Totally-Unknown-Theme")
  }

  @Test
  func knownIDsHaveNoDuplicateRawValues() {
    let rawValues = CodeThemeID.knownIDs.map(\.rawValue)
    #expect(rawValues.count == Set(rawValues).count)
  }

  @Test
  func everyKnownIDHasANonEmptyDisplayName() {
    #expect(CodeThemeID.knownIDs.allSatisfy { !$0.displayName.isEmpty })
  }
}
