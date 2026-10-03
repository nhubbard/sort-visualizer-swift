import XCTest

/// Proves the Export/Import Tape buttons (see Documentation/docs/architecture/history.md for the
/// feature's origin) are actually wired into the running app and reachable — the same
/// "reachable and functional" bar `RunControlBarUITests` sets for the rest of the run control
/// bar. Catalyst also exercises the full native save, relaunch, and import flow; iPad tests
/// verify panel presentation while archive and coordinator tests verify the data path.
@MainActor
final class TapeExportImportUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    useLandscapeOrientationForUITest()
  }

  /// The iPad accessibility trees identify the system share sheet as
  /// `ShareSheet.RemoteContainerView` and the file importer as `Browse View (Picker)`. Catalyst
  /// exposes native save/open panels as sheets in the current runtime. Keep the tree attachment
  /// when none appears so a future OS presentation change remains diagnosable.
  private func waitForNativePanelPresentation(
    in app: XCUIApplication, trigger: XCUIElement, iosIdentifier: String,
    timeout: TimeInterval, testCase: XCTestCase
  ) -> Bool {
    let initialWindowCount = app.windows.count
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if app.otherElements[iosIdentifier].exists || app.sheets.firstMatch.exists
        || app.dialogs.firstMatch.exists
        || app.windows.count > initialWindowCount {
        return true
      }
      #if targetEnvironment(macCatalyst)
        // Native NSSavePanel/NSOpenPanel may live outside the Catalyst app's XCUI tree on a
        // future macOS release. While modal, it blocks hit testing on its trigger button.
        if !trigger.isHittable { return true }
      #endif
      Thread.sleep(forTimeInterval: 0.1)
    }
    let attachment = XCTAttachment(string: app.debugDescription)
    attachment.name = "accessibility-tree-at-timeout"
    attachment.lifetime = .keepAlways
    testCase.add(attachment)
    let screen = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screen.name = "entire-screen-at-timeout"
    screen.lifetime = .keepAlways
    testCase.add(screen)
    return false
  }

  func testExportTapeButtonPresentsAShareSheet() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    app.tapSidebarLink("algorithmLink.quicksort")

    let exportButton = app.buttons["runControlExportTapeButton"]
    XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "Export Tape button never appeared")
    XCTAssertTrue(exportButton.isEnabled, "Export Tape button should be enabled once a tape exists")
    #if targetEnvironment(macCatalyst)
      XCTAssertTrue(exportButton.isHittable)
    #endif

    #if targetEnvironment(macCatalyst)
      exportButton.click()
    #else
      exportButton.tap()
    #endif

    XCTAssertTrue(
      waitForNativePanelPresentation(
        in: app, trigger: exportButton, iosIdentifier: "ShareSheet.RemoteContainerView",
        timeout: 5, testCase: self),
      "Export Tape should present a share sheet")

    // Dismiss however this platform's share sheet responds to Escape, so the test doesn't leave
    // it hanging for whatever runs next.
    app.typeKey(.escape, modifierFlags: [])
  }

  func testImportTapeButtonExistsInToolbar() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    #if targetEnvironment(macCatalyst)
      // SwiftUI identifiers are not forwarded into Catalyst's native NSToolbar. Its import
      // button is exposed to accessibility by the SF Symbol name instead.
      let importButton = app.buttons["download"]
    #else
      let importButton = app.buttons["importTapeButton"]
    #endif
    XCTAssertTrue(importButton.waitForExistence(timeout: 5), "Import Tape button never appeared")
    XCTAssertTrue(importButton.isEnabled, "Import Tape button should always be enabled")
    #if targetEnvironment(macCatalyst)
      XCTAssertTrue(importButton.isHittable)
    #endif

    #if targetEnvironment(macCatalyst)
      importButton.click()
    #else
      importButton.tap()
    #endif

    // Same rationale as the export test above.
    XCTAssertTrue(
      waitForNativePanelPresentation(
        in: app, trigger: importButton, iosIdentifier: "Browse View (Picker)",
        timeout: 5, testCase: self),
      "Import Tape should present a file importer")

    app.typeKey(.escape, modifierFlags: [])
  }

  #if targetEnvironment(macCatalyst)
    func testSavedTapeImportsIntoAFreshAppSession() throws {
      let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("sort-symphony-tape-ui-\(UUID().uuidString)")
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: folder) }
      let archiveURL = folder.appendingPathComponent("roundtrip.tape")

      let app = XCUIApplication()
      app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1000"]
      app.launch()
      app.tapSidebarLink("algorithmLink.quicksort")

      let exportButton = app.buttons["runControlExportTapeButton"]
      XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
      exportButton.click()
      let savePanel = app.sheets["save-panel"]
      XCTAssertTrue(savePanel.waitForExistence(timeout: 5))
      goToFolder(folder, in: app)
      XCTAssertEqual(savePanel.popUpButtons["where popup"].value as? String, folder.lastPathComponent)
      let name = savePanel.textFields["saveAsNameTextField"]
      name.click()
      name.typeKey("a", modifierFlags: .command)
      name.typeText("roundtrip")
      savePanel.buttons["OKButton"].click()
      let saved = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in FileManager.default.fileExists(atPath: archiveURL.path) },
        object: nil)
      XCTAssertEqual(XCTWaiter().wait(for: [saved], timeout: 5), .completed)
      XCTAssertGreaterThan(try Data(contentsOf: archiveURL).count, 100)

      app.terminate()
      app.launch()
      app.buttons["download"].click()
      let openPanel = app.sheets["open-panel"]
      XCTAssertTrue(openPanel.waitForExistence(timeout: 5))
      goToFolder(folder, in: app)
      XCTAssertEqual(openPanel.popUpButtons["where popup"].value as? String, folder.lastPathComponent)
      let file = openPanel.textFields.matching(
        NSPredicate(format: "value CONTAINS %@", "roundtrip")).firstMatch
      if !file.waitForExistence(timeout: 5) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "open-panel-missing-archive"
        tree.lifetime = .keepAlways
        add(tree)
        XCTFail("the saved tape is missing from the open panel")
        return
      }
      file.click()
      openPanel.buttons["OKButton"].click()

      let status = app.staticTexts["sortStatusLabel"]
      XCTAssertTrue(status.waitForExistence(timeout: 10))
      let sorted = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "value == %@", "sorted"), object: status)
      XCTAssertEqual(XCTWaiter().wait(for: [sorted], timeout: 30), .completed)
    }

    func testCorruptTapeShowsARecoverableImportError() throws {
      let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("sort-symphony-corrupt-tape-ui-\(UUID().uuidString)")
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: folder) }
      try Data("not a tape archive".utf8).write(to: folder.appendingPathComponent("corrupt.tape"))

      let app = XCUIApplication()
      app.launch()
      app.buttons["download"].click()
      let openPanel = app.sheets["open-panel"]
      XCTAssertTrue(openPanel.waitForExistence(timeout: 5))
      goToFolder(folder, in: app)
      let file = openPanel.textFields.matching(
        NSPredicate(format: "value CONTAINS %@", "corrupt")).firstMatch
      XCTAssertTrue(file.waitForExistence(timeout: 5), "the corrupt fixture is missing from the panel")
      file.click()
      openPanel.buttons["OKButton"].click()

      // SwiftUI alerts are exposed as native sheets on Catalyst.
      let alert = app.sheets["alert"]
      XCTAssertTrue(alert.waitForExistence(timeout: 10), "a corrupt tape must show a visible error")
      XCTAssertTrue(alert.staticTexts.matching(
        NSPredicate(format: "value == %@", "Import Failed")
      ).firstMatch.exists)
      XCTAssertTrue(alert.staticTexts.matching(
        NSPredicate(format: "value BEGINSWITH %@", "Couldn't import")
      ).firstMatch.exists)
      alert.buttons["OK"].click()
      XCTAssertFalse(alert.exists, "the user must be able to dismiss the import error")
      XCTAssertFalse(app.staticTexts["sortStatusLabel"].exists)
    }

    private func goToFolder(_ folder: URL, in app: XCUIApplication) {
      app.typeKey("g", modifierFlags: [.command, .shift])
      app.typeText(folder.path)
      app.typeKey(.return, modifierFlags: [])
    }
  #endif
}
