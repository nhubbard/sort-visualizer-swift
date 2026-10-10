import XCTest

/// Exercises native tape save/import controls and verifies that an imported tape replays the
/// same recorded run after app relaunch. The engine's archive tests cover exact operation data.
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
      // SwiftUI identifiers are not forwarded into Catalyst's native NSToolbar, but the
      // semantic Label title remains available as the button's accessible name.
      let importButton = app.buttons["Import Tape"]
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

  private var tapeEnvironment: [String: String] {
    ["UI_TEST_ARRAY_SIZE": "24", "UI_TEST_PLAYBACK_SPEED": "1000",
      "UI_TEST_DETERMINISTIC_REPLAY": "1", "UI_TEST_EXPOSE_FRAME": "1",
      "UI_TEST_TAPE_METADATA_PROBE": "1"]
  }

  private func completedTapeSnapshot(in app: XCUIApplication) -> (metadata: String, frame: String) {
    let status = app.staticTexts["sortStatusLabel"]
    let sorted = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "sorted"), object: status)
    XCTAssertEqual(XCTWaiter().wait(for: [sorted], timeout: 60), .completed)
    let canvas = app.descendants(matching: .any)
      .matching(identifier: "sortVisualizationCanvas").firstMatch
    XCTAssertTrue(canvas.waitForExistence(timeout: 5))
    app.activateControlForUITest(app.buttons["runControlJumpToEndButton"])
    let value = canvas.value as? String ?? ""
    XCTAssertTrue(value.contains("|"), "missing replay frame probe")
    let metadata = canvas.label
    XCTAssertTrue(metadata.contains("|"), "missing tape metadata probe")
    return (metadata, value)
  }

  #if !targetEnvironment(macCatalyst)
  private func saveTapeToFiles(in app: XCUIApplication, named filename: String) {
    app.buttons["runControlExportTapeButton"].tap()
    XCTAssertTrue(app.cells["Save to Files"].waitForExistence(timeout: 5))
    app.cells["Save to Files"].tap()
    XCTAssertTrue(app.otherElements["Browse View (Picker)"].waitForExistence(timeout: 10))
    let name = app.textFields["DOCPicker.filenameTextField"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeKey("a", modifierFlags: .command)
    name.typeText(filename)
    app.buttons["DOCPicker.actionButton"].tap()
    let picker = app.otherElements["Browse View (Picker)"]
    let dismissed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == false"), object: picker)
    XCTAssertEqual(XCTWaiter().wait(for: [dismissed], timeout: 10), .completed)
  }

  private func importFileFromFiles(in app: XCUIApplication, named filename: String) {
    app.buttons["importTapeButton"].tap()
    XCTAssertTrue(app.otherElements["Browse View (Picker)"].waitForExistence(timeout: 10))
    let file = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label CONTAINS %@", filename)).firstMatch
    if !file.waitForExistence(timeout: 10) {
      let tree = XCTAttachment(string: app.debugDescription)
      tree.name = "ipad-import-picker-missing-archive"
      tree.lifetime = .keepAlways
      add(tree)
      XCTFail("saved tape missing from iPad import picker")
      return
    }
    file.tap()
  }

  func testSavedTapeImportsIntoAFreshAppSession() {
    let app = XCUIApplication()
    app.launchEnvironment = tapeEnvironment
    app.launch()
    app.buttons["algorithmLink.threesmoothcombsortiterative"].tap()
    let original = completedTapeSnapshot(in: app)
    let filename = "tap02-\(UUID().uuidString)"
    saveTapeToFiles(in: app, named: filename)

    app.terminate()
    app.launch()
    importFileFromFiles(in: app, named: filename)
    let imported = completedTapeSnapshot(in: app)
    XCTAssertEqual(imported.metadata, original.metadata)
    XCTAssertEqual(imported.frame, original.frame)
  }

  func testCorruptTapeShowsARecoverableImportError() {
    let app = XCUIApplication()
    app.launchEnvironment = tapeEnvironment.merging(["UI_TEST_EXPORT_CORRUPT_TAPE": "1"]) { _, new in new }
    app.launch()
    app.buttons["algorithmLink.threesmoothcombsortiterative"].tap()
    _ = completedTapeSnapshot(in: app)
    let filename = "tap02-corrupt-\(UUID().uuidString)"
    saveTapeToFiles(in: app, named: filename)

    app.terminate()
    app.launchEnvironment = tapeEnvironment
    app.launch()
    app.buttons["algorithmLink.threesmoothcombsortiterative"].tap()
    let original = completedTapeSnapshot(in: app)
    importFileFromFiles(in: app, named: filename)
    let alert = app.alerts["Import Failed"]
    XCTAssertTrue(alert.waitForExistence(timeout: 10), "a corrupt tape must show a visible error")
    XCTAssertTrue(alert.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Couldn't import")
    ).firstMatch.exists)
    alert.buttons["OK"].tap()
    XCTAssertFalse(alert.exists)
    let afterFailure = completedTapeSnapshot(in: app)
    XCTAssertEqual(afterFailure.metadata, original.metadata)
    XCTAssertEqual(afterFailure.frame, original.frame)
  }
  #endif

  #if targetEnvironment(macCatalyst)
    func testSavedTapeImportsIntoAFreshAppSession() throws {
      let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("sort-symphony-tape-ui-\(UUID().uuidString)")
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: folder) }
      let archiveURL = folder.appendingPathComponent("roundtrip.tape")

      let app = XCUIApplication()
      app.launchEnvironment = tapeEnvironment
      app.launch()
      app.tapSidebarLink("algorithmLink.quicksort")
      let original = completedTapeSnapshot(in: app)

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
      app.buttons["Import Tape"].click()
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

      let imported = completedTapeSnapshot(in: app)
      XCTAssertEqual(imported.metadata, original.metadata)
      XCTAssertEqual(imported.frame, original.frame)
    }

    func testCorruptTapeShowsARecoverableImportError() throws {
      let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("sort-symphony-corrupt-tape-ui-\(UUID().uuidString)")
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: folder) }
      try Data("not a tape archive".utf8).write(to: folder.appendingPathComponent("corrupt.tape"))

      let app = XCUIApplication()
      app.launchEnvironment = tapeEnvironment
      app.launch()
      app.tapSidebarLink("algorithmLink.quicksort")
      let original = completedTapeSnapshot(in: app)
      app.buttons["Import Tape"].click()
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
      let afterFailure = completedTapeSnapshot(in: app)
      XCTAssertEqual(afterFailure.metadata, original.metadata)
      XCTAssertEqual(afterFailure.frame, original.frame)
    }

    private func goToFolder(_ folder: URL, in app: XCUIApplication) {
      app.typeKey("g", modifierFlags: [.command, .shift])
      app.typeText(folder.path)
      app.typeKey(.return, modifierFlags: [])
    }
  #endif
}
