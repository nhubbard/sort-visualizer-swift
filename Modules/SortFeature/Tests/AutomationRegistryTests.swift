import SwiftUI
import Testing

@testable import SortFeature

@Suite
struct AutomationRegistryTests {
  private func makeAutomation(
    id: AutomationID, key: KeyEquivalent = "a", modifiers: EventModifiers = []
  ) -> Automation {
    Automation(
      id: id, displayName: id.rawValue, iconName: "gear", key: key, modifiers: modifiers,
      runsPerSize: 1, sizes: { _ in [] })
  }

  @Test
  func shortcutDisplayStringOrdersModifiersControlOptionShiftCommand() {
    let automation = makeAutomation(
      id: .sizeSweep, key: "a", modifiers: [.command, .shift, .option, .control])
    #expect(automation.shortcutDisplayString == "⌃⌥⇧⌘A")
  }

  @Test
  func shortcutDisplayStringWithNoModifiersIsJustTheUppercasedKey() {
    let automation = makeAutomation(id: .sizeSweep, key: "z", modifiers: [])
    #expect(automation.shortcutDisplayString == "Z")
  }

  @MainActor
  @Test
  func automationLookupReturnsNilForAnUnregisteredID() {
    let registry = AutomationRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = [makeAutomation(id: .sizeSweep)]
    registry.discover()

    #expect(registry.automation(id: .sizeSweep) != nil)
    #expect(registry.automation(id: .maxSizeOnly) == nil)
  }

  @MainActor
  @Test
  func discoverCopiesBuiltInsIntoAutomationsAndIsNotLiveUntilCalled() {
    let registry = AutomationRegistry.shared
    let restoreBuiltIns = registry.builtIns
    defer {
      registry.builtIns = restoreBuiltIns
      registry.discover()
    }
    registry.builtIns = []
    registry.discover()
    #expect(registry.automations.isEmpty)

    registry.builtIns = [makeAutomation(id: .sizeSweep), makeAutomation(id: .maxSizeOnly)]
    // Not yet reflected in `automations` until `discover()` runs again.
    #expect(registry.automations.isEmpty)

    registry.discover()
    #expect(registry.automations.count == 2)
  }
}
