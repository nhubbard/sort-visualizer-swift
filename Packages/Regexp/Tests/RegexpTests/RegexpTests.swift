import XCTest
@testable import Regexp

final class RegexpTests: XCTestCase {
  static let pattern: String = #"(.+?)([1,2,3]*)(.*)"#
  let regexp: RegexpProtocol = try! Regexp(pattern: RegexpTests.pattern, groupNames: "letter", "digits", "rest")
  let source = "l321321alala"
  let letter = "l"
  let digits = "321321"
  let rest = "alala"
  let replaceAllTemplate = "$1-$2-$3"
  let replaceAllResult = "l-321321-alala"
  
  let names = "Harry Trump ;Fred Barney; Helen Rigby ; Bill Abel ;Chris Hand"
  let namesSplitPattern = #"\s*;\s*"#
  let splitNames = ["Harry Trump", "Fred Barney", "Helen Rigby", "Bill Abel", "Chris Hand"]
  
  func testMatches() {
    XCTAssert(regexp.matches(source))
    XCTAssert(source =~ regexp)
    XCTAssert(source =~ RegexpTests.pattern)
    XCTAssertFalse(source !~ regexp)
    XCTAssertFalse(source !~ RegexpTests.pattern)
  }
  
  func testSwitch() {
    let exp1 = self.expectation(description: "Alpha matching works")
    switch letter {
      case "\\d".r: XCTFail("Letter should not match a digit")
      case "[a-z]".r: exp1.fulfill()
      default: XCTFail("Letter should have matched alpha")
    }
    let exp2 = self.expectation(description: "Alpha matching works")
    switch digits {
      case "[a-z]+".r: XCTFail("Digits should not match letters")
      case "[A-Z]+".r: XCTFail("Digits should not match capital letters")
      default: exp2.fulfill()
    }
    self.waitForExpectations(timeout: 0, handler: nil)
  }
  
  func testSimple() {
    XCTAssertEqual(RegexpTests.pattern.r?.findFirst(in: source)?.group(at: 2), digits)
  }
  
  private func _test(group name: String, reference: String) {
    let matches = regexp.findAll(in: source)
    for match in matches {
      let value = match.group(named: name)
      XCTAssertEqual(value, reference)
    }
  }
  
  func testLetter() {
    _test(group: "letter", reference: letter)
  }
  
  func testDigits() {
    _test(group: "digits", reference: digits)
  }
  
  func testRest() {
    _test(group: "rest", reference: rest)
  }
  
  func testFirstMatch() {
    let match = regexp.findFirst(in: source)
    XCTAssertNotNil(match)
    if let match = match {
      XCTAssertEqual(letter, match.group(named: "letter"))
      XCTAssertEqual(digits, match.group(named: "digits"))
      XCTAssertEqual(rest, match.group(named: "rest"))
      XCTAssertEqual(source, match.matched)
      let subgroups = match.subgroups
      XCTAssertEqual(letter, subgroups[0])
      XCTAssertEqual(digits, subgroups[1])
      XCTAssertEqual(rest, subgroups[2])
    } else {
      XCTFail("Bad test -- can't reach this path!")
    }
  }
  
  func testReplaceAll() {
    let replaced = regexp.replaceAll(in: source, with: replaceAllTemplate)
    XCTAssertEqual(replaceAllResult, replaced)
  }
  
  func testReplaceAllWithReplacer() {
    let replaced = "(.+?)([1,2,3]+)(.+?)".r?.replaceAll(in: "l321321la321a") { match in
      if match.group(at: 1) == "l" {
        return nil
      } else {
        return match.matched.uppercased()
      }
    }
    XCTAssertEqual("l321321lA321A", replaced)
  }
  
  func testReplaceFirst() {
    let replaced = "(.+?)([1,2,3]+)(.+?)".r?.replaceFirst(in: "l321321la321a", with: "$1-$2-$3-")
    XCTAssertEqual("l-321321-l-a321a", replaced)
  }
  
  func testReplaceFirstWithReplacer() {
    let _regexp = #"(.+?)([1,2,3]+)(.+?)"#.r
    let replaced1 = _regexp?.replaceFirst(in: "l321321la321a") { match in
      return match.matched.uppercased()
    }
    XCTAssertEqual("L321321La321a", replaced1)
    
    let replaced2 = _regexp?.replaceFirst(in: "l321321la321a") { match in
      return nil
    }
    XCTAssertEqual("l321321la321a", replaced2)
  }
  
  func testGraphemeClusters() {
    let testString = """
            👍👍 Find me. 👌👨‍👩‍👧👨\u{200D}👩\u{200D}👧👌
            """
    let regex = try! Regexp(pattern: "^(👍+) *([^👌]+?) *([👌👨‍👩‍👧]+)$", options: [.anchorsMatchLines], groupNames: [])
    guard let firstMatch = regex.findFirst(in: testString) else {
      return XCTFail("Failed to find first match using anchored regex.")
    }
    XCTAssert(firstMatch.group(at: 1) == "👍👍", "Incorrect first capture group for anchored regex.")
    XCTAssert(firstMatch.group(at: 2) == "Find me.", "Incorrect second capture group for anchored regex.")
    XCTAssert(firstMatch.group(at: 3) == "👌👨‍👩‍👧👨‍👩‍👧👌", "Incorrect third capture group for anchored regex.")
    let englishMatchSequence = regex.findAll(in: testString)
    XCTAssert(englishMatchSequence.context.count == 1, "Failed to find match using anchored regex.")
    let englishFirstMatch = englishMatchSequence.makeIterator().next()!
    XCTAssert(englishFirstMatch.group(at: 1) == "👍👍", "Incorrect first capture group for anchored regex.")
    XCTAssert(englishFirstMatch.group(at: 2) == "Find me.", "Incorrect second capture group for anchored regex.")
    XCTAssert(englishFirstMatch.group(at: 3) == "👌👨‍👩‍👧👨‍👩‍👧👌", "Incorrect third capture group for anchored regex.")
    
    
    let familyEmojiRegex = try! Regexp(pattern: "👌([👨‍👩‍👧]+)", groupNames: [])
    guard let familyFirstMatch = familyEmojiRegex.findFirst(in: testString) else {
      return XCTFail("Failed to find first match using family regex.")
    }
    XCTAssert(familyFirstMatch.matched == "👌👨‍👩‍👧👨‍👩‍👧", "Incorrect matched string for family emoji regex.")
    XCTAssert(familyFirstMatch.group(at: 1) == "👨‍👩‍👧👨‍👩‍👧", "Incorrect first capture group for family emoji regex.")
    
    let testInArabic = "اختبار"
    let arabicTestString = "🇦🇪 مرحبًا ، هذا اختبار"
    let arabicRegex = try! Regexp(pattern: testInArabic, groupNames: [])
    let arabicMatchSequence = arabicRegex.findAll(in: arabicTestString)
    XCTAssert(arabicMatchSequence.context.count == 1, "Failed to find match in Arabic test string.")
    let arabicFirstMatch = arabicMatchSequence.makeIterator().next()!
    XCTAssert(arabicFirstMatch.matched == testInArabic, "Failed to match Arabic.")
    
    let testInThai = "ทดสอบ"
    let thaiTestString = "🇹🇭 สวัสดีนี่เป็นแบบทดสอบ"
    let thaiRegex = try! Regexp(pattern: testInThai, groupNames: [])
    let thaiMatchSequence = thaiRegex.findAll(in: thaiTestString)
    XCTAssert(thaiMatchSequence.context.count == 1, "Failed to find match in Thai test string.")
    let thaiFirstMatch = thaiMatchSequence.makeIterator().next()!
    XCTAssert(thaiFirstMatch.matched == testInThai, "Failed to match Thai.")
  }
  
  func testSplit() {
    let re = namesSplitPattern.r!
    let nameList = re.split(names)
    XCTAssertEqual(nameList, splitNames)
  }
  
  func testSplitOnString() {
    let nameList = names.split(using: namesSplitPattern.r)
    XCTAssertEqual(nameList, splitNames)
  }
  
  func testSplitWithSubgroups() {
    let myString = "Hello 1 word. Sentence number 2."
    let splits = myString.split(using: #"(\d)"#.r)
    XCTAssertEqual(splits, ["Hello ", "1", " word. Sentence number ", "2", "."])
  }
  
  func testNonExistingGroup() {
    let PATH_REGEXP = [
      "(\\\\.)",
      "([\\/.])?(?:(?:\\:(\\w+)(?:\\(((?:\\\\.|[^()])+)\\))?|\\(((?:\\\\.|[^()])+)\\))([+*?])?|(\\*))"
    ].joined(separator: "|").r!
    let match = PATH_REGEXP.findFirst(in: "/:test(\\d+)?")!
    XCTAssertNil(match.group(at: 1))
    XCTAssertNotNil(match.group(at: 2))
  }
  
  func testSubscriptAccess() {
    let match = regexp.findFirst(in: source)
    XCTAssertNotNil(match)
    if let match = match {
      let groups = match.groups
      XCTAssertEqual(letter, groups["letter"])
      XCTAssertEqual(digits, groups["digits"])
      XCTAssertEqual(rest, groups["rest"])
      XCTAssertNil(groups["unexisted"])
      XCTAssertEqual(source, groups[0])
      XCTAssertEqual(letter, groups[1])
      XCTAssertEqual(digits, groups[2])
      XCTAssertEqual(rest, groups[3])
      XCTAssertNil(groups[4])
    } else {
      XCTFail("Bad test, can't reach this path!")
    }
  }
}
