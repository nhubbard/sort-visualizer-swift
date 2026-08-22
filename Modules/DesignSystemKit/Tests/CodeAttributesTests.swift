import Testing

@testable import DesignSystemKit

@Suite
struct CodeAttributesTests {
  @Test
  func topLevelTokenHasNoParent() {
    #expect(CodeAttributes.Value.token.parent == nil)
  }

  @Test
  func twoComponentTokensParentIsTheFirstComponent() {
    #expect(CodeAttributes.Value.keyword.parent == .token)
    #expect(CodeAttributes.Value.string.parent == .literal)
  }

  @Test
  func threeComponentTokensParentDropsOnlyTheLastComponent() {
    #expect(CodeAttributes.Value.numberIntegerLong.parent == .numberInteger)
    #expect(CodeAttributes.Value.keywordConstant.parent == .keyword)
  }

  @Test
  func walkingParentChainAlwaysReachesTokenThenNil() {
    var current: CodeAttributes.Value? = .numberIntegerLong
    var chain: [CodeAttributes.Value] = []
    while let value = current {
      chain.append(value)
      current = value.parent
    }
    #expect(chain == [.numberIntegerLong, .numberInteger, .number, .literal, .token])
  }
}
