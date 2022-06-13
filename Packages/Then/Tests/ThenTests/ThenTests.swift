import XCTest
@testable import Then

struct User {
  var name: String?
  var email: String?
}

extension User: Then {}

final class ThenTests: XCTestCase {
  func testNSObject() {
    let queue = OperationQueue().then {
      $0.name = "awesome"
      $0.maxConcurrentOperationCount = 5
    }
    XCTAssertEqual(queue.name, "awesome")
    XCTAssertEqual(queue.maxConcurrentOperationCount, 5)
  }
  
  func testThenIfNSObject() {
    let shouldModifyQueue = false
    let queue = OperationQueue().thenIf(shouldModifyQueue) {
      $0.name = "awesome"
      $0.maxConcurrentOperationCount = 5
    }
    XCTAssertNotEqual(queue.name, "awesome")
    XCTAssertNotEqual(queue.maxConcurrentOperationCount, 5)
  }
  
  func testWith() {
    let user = User().with {
      $0.name = "example"
      $0.email = "example@example.com"
    }
    XCTAssertEqual(user.name, "example")
    XCTAssertEqual(user.email, "example@example.com")
  }
  
  func testWithIf() {
    let shouldModifyUser = false
    let user = User().withIf(shouldModifyUser) {
      $0.name = "example"
      $0.email = "example@example.com"
    }
    XCTAssertNotEqual(user.name, "example")
    XCTAssertNotEqual(user.email, "example@example.com")
  }
  
  func testWithArray() {
    let array = [1, 2, 3].with { $0.append(4) }
    XCTAssertEqual(array, [1, 2, 3, 4])
  }
  
  func testWithIfArray() {
    let shouldModifyArray = false
    let array = [1, 2, 3].withIf(shouldModifyArray) { $0.append(4) }
    XCTAssertNotEqual(array, [1, 2, 3, 4])
  }
  
  func testWithDictionary() {
    let dict = ["Korea": "Seoul", "Japan": "Tokyo"].with {
      $0["China"] = "Beijing"
    }
    XCTAssertEqual(dict, ["Korea": "Seoul", "Japan": "Tokyo", "China": "Beijing"])
  }
  
  func testWithIfDictionary() {
    let shouldModifyDict = false
    let dict = ["Korea": "Seoul", "Japan": "Tokyo"].withIf(shouldModifyDict) {
      $0["China"] = "Beijing"
    }
    XCTAssertNotEqual(dict, ["Korea": "Seoul", "Japan": "Tokyo", "China": "Beijing"])
  }
  
  func testWithSet() {
    let set = Set(["A", "B", "C"]).with {
      $0.insert("D")
    }
    XCTAssertEqual(set, Set(["A", "B", "C", "D"]))
  }
  
  func testWithIfSet() {
    let shouldModifySet = false
    let set = Set(["A", "B", "C"]).withIf(shouldModifySet) {
      $0.insert("D")
    }
    XCTAssertNotEqual(set, Set(["A", "B", "C", "D"]))
  }
  
  func testDo() {
    UserDefaults.standard.do {
      $0.removeObject(forKey: "username")
      $0.set("example", forKey: "username")
      $0.synchronize()
    }
    XCTAssertEqual(UserDefaults.standard.string(forKey: "username"), "example")
  }
  
  func testDoIf() {
    UserDefaults.standard.do {
      $0.removeObject(forKey: "username")
      $0.synchronize()
    }
    XCTAssertNotEqual(UserDefaults.standard.string(forKey: "username"), "devxoul")
    let shouldModifyUserDefaults = false
    UserDefaults.standard.doIf(shouldModifyUserDefaults) {
      $0.removeObject(forKey: "username")
      $0.set("devxoul", forKey: "username")
      $0.synchronize()
    }
    XCTAssertNotEqual(UserDefaults.standard.string(forKey: "username"), "devxoul")
  }
  
  func testLet() {
    let state: Bool = UserDefaults.standard.let {
      $0.removeObject(forKey: "username")
      $0.set("example", forKey: "username")
      return $0.synchronize()
    }
    XCTAssertEqual(state, true)
  }
  
  func testDoRethrows() {
    XCTAssertThrowsError(
      try NSObject().do { _ in
        throw NSError(domain: "", code: 0)
      }
    )
  }
  
  func testDoIfRethrows() {
    let shouldThrowError = false
    XCTAssertNoThrow(
      try NSObject().doIf(shouldThrowError) { _ in
        throw NSError(domain: "", code: 0)
      }
    )
  }
}
