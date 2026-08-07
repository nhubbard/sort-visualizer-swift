import XCTest

/// Proves the Export/Import Tape buttons (Phase 3 of `IMPLEMENTATION_PLAN.md`'s tape
/// export/import stretch goal) are actually wired into the running app and reachable — the same
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
    // hierarchy, but it's still presented as a `.sheet`-typed element XCUITest can at least see
    // exists — enough to confirm tapping the button didn't crash and genuinely presented
    // something, without asserting on the share sheet's own contents.
    XCTAssertTrue(
      app.sheets.firstMatch.waitForExistence(timeout: 5),
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

    // Same rationale as the export test above: the file-open panel is mostly system UI, but
    // still presented as a `.sheet`-typed element this test can confirm actually appeared.
    XCTAssertTrue(
      app.sheets.firstMatch.waitForExistence(timeout: 5),
      "Import Tape should present a file importer")

    app.typeKey(.escape, modifierFlags: [])
  }
}
