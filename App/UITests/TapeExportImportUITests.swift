import XCTest

/// Proves the Export/Import Tape buttons (see Documentation/docs/architecture/history.md for the
/// feature's origin) are actually wired into the running app and reachable — the same
/// "reachable and functional" bar `RunControlBarUITests` sets for the rest of the run control
/// bar. Doesn't attempt a full save-to-disk-then-reimport round trip: the system share sheet
/// (`ShareLink`) and file-open panel (`.fileImporter`) both live outside this app's own
/// accessibility hierarchy, and automating "actually complete a save/open dialog" reliably across
/// macOS versions is its own brittle project — `TapeArchiveTests`/`SortCoordinatorTests` already
/// cover the actual encode/decode/routing correctness this UI just has to trigger.
@MainActor
final class TapeExportImportUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .landscapeLeft
  }

  /// Polls for ANY plausible sign the native save/open panel presented, across the element types
  /// and window-count changes a `.sheet`/`.dialog`/independent-window classification could each
  /// produce — two prior guesses at the "right" element type (`.sheets` alone, then
  /// `.sheets`-or-`.dialogs`) both failed even though the panel demonstrably appears when this
  /// same button is tapped manually, so this no longer guesses a specific type. If NONE of them
  /// match within `timeout`, attaches the full accessibility tree (`app.debugDescription`) to the
  /// test result — the same technique `SettingsUITests`' own `resetSettingsConfirmButton` fix was
  /// diagnosed with — so the actual element type can be read off directly instead of guessed a
  /// third time.
  private func waitForNativePanelPresentation(
    in app: XCUIApplication, timeout: TimeInterval, testCase: XCTestCase
  ) -> Bool {
    let initialWindowCount = app.windows.count
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if app.sheets.firstMatch.exists || app.dialogs.firstMatch.exists
        || app.windows.count > initialWindowCount {
        return true
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    let attachment = XCTAttachment(string: app.debugDescription)
    attachment.name = "accessibility-tree-at-timeout"
    attachment.lifetime = .keepAlways
    testCase.add(attachment)
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

    exportButton.tap()

    // The share sheet itself is system UI mostly outside this app's own accessibility
    // hierarchy — see `waitForNativePanelPresentation`'s own doc comment for why this no longer
    // asserts on one specific element type.
    XCTAssertTrue(
      waitForNativePanelPresentation(in: app, timeout: 5, testCase: self),
      "Export Tape should present a share sheet")

    // Dismiss however this platform's share sheet responds to Escape, so the test doesn't leave
    // it hanging for whatever runs next.
    app.typeKey(.escape, modifierFlags: [])
  }

  func testImportTapeButtonExistsInToolbar() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TEST_ARRAY_SIZE": "24"]
    app.launch()

    let importButton = app.buttons["importTapeButton"]
    XCTAssertTrue(importButton.waitForExistence(timeout: 5), "Import Tape button never appeared")
    XCTAssertTrue(importButton.isEnabled, "Import Tape button should always be enabled")

    importButton.tap()

    // Same rationale as the export test above.
    XCTAssertTrue(
      waitForNativePanelPresentation(in: app, timeout: 5, testCase: self),
      "Import Tape should present a file importer")

    app.typeKey(.escape, modifierFlags: [])
  }
}
