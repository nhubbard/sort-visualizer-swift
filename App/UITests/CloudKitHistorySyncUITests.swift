import XCTest

/// Run these phases separately on two signed-in devices with the same canary marker. They are
/// skipped during ordinary UI suites so they never write synthetic history by accident.
@MainActor
final class CloudKitHistorySyncUITests: XCTestCase {
  private var marker: String {
    "his02-canary-\(ProcessInfo.processInfo.environment["HIS02_CANARY_SUFFIX"] ?? "contract-20261003")"
  }

  private func launchCanary(action: String? = nil) throws -> (XCUIApplication, XCUIElement) {
    guard ProcessInfo.processInfo.environment["HIS02_RUN_CANARY"] == "1" else {
      throw XCTSkip("Set HIS02_RUN_CANARY=1 only for a signed-in, two-device sync check")
    }
    let app = XCUIApplication()
    app.launchEnvironment = [
      "UI_TEST_CLOUDKIT_CANARY_ID": marker,
      "UI_TEST_ARRAY_SIZE": "16",
      "UI_TEST_PLAYBACK_SPEED": "100000",
    ]
    if let action { app.launchEnvironment["UI_TEST_CLOUDKIT_CANARY_ACTION"] = action }
    app.launch()
    let probe = app.staticTexts["cloudKitCanaryProbe"]
    XCTAssertTrue(probe.waitForExistence(timeout: 10))
    return (app, probe)
  }

  func testWriteCanaryOnFirstDevice() throws {
    let (_, probe) = try launchCanary(action: "write")
    let written = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "count:1"), object: probe)
    XCTAssertEqual(XCTWaiter().wait(for: [written], timeout: 30), .completed,
      "Canary status: \(probe.value ?? "missing")")
    // SwiftData exports after the local save. Keep the process alive for the server-side check.
    let hold = TimeInterval(
      ProcessInfo.processInfo.environment["HIS02_EXPORT_HOLD_SECONDS"] ?? "90") ?? 90
    Thread.sleep(forTimeInterval: min(max(hold, 0), 1800))
  }

  func testObserveCanaryOnSecondDevice() throws {
    let (_, probe) = try launchCanary(action: "observe")
    let deadline = Date().addingTimeInterval(300)
    while Date() < deadline {
      if probe.value as? String == "count:1" { return }
      Thread.sleep(forTimeInterval: 5)
    }
    XCTFail("Canary \(marker) did not sync to this device: \(probe.value ?? "missing")")
  }

  func testObserveServerDeletion() throws {
    let (_, probe) = try launchCanary(action: "observeDelete")
    let present = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "count:1"), object: probe)
    XCTAssertEqual(XCTWaiter().wait(for: [present], timeout: 30), .completed,
      "Canary must exist locally before the server deletion: \(probe.value ?? "missing")")
    let removed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "count:0"), object: probe)
    XCTAssertEqual(XCTWaiter().wait(for: [removed], timeout: 600), .completed,
      "The normal SwiftData store did not import the CloudKit deletion: \(probe.value ?? "missing")")
  }

  func testDeletedCanaryIsAbsentAfterRelaunch() throws {
    let (_, probe) = try launchCanary(action: "observeDelete")
    let removed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "count:0"), object: probe)
    XCTAssertEqual(XCTWaiter().wait(for: [removed], timeout: 300), .completed,
      "Canary deleted on CloudKit still exists in the normal SwiftData store: \(probe.value ?? "missing")")
  }

  func testDeleteCanaryAfterBothDevicesObservedIt() throws {
    let (_, probe) = try launchCanary(action: "delete")
    let deleted = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "count:0"), object: probe)
    XCTAssertEqual(XCTWaiter().wait(for: [deleted], timeout: 15), .completed)
  }
}
