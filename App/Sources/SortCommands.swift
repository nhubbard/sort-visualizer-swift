import SettingsKit
import SortFeature
import SwiftUI

/// Scene-level replacement for every shortcut that used to live as an invisible, zero-size
/// `Button` inside `ScrollingSortView`/`RunControlBar` — those never showed up in the menu bar or
/// the ⌘-hold shortcuts HUD, since nothing outside SwiftUI's own responder chain could see them.
/// `SortCoordinator.shared` already exposes "whichever sort is on screen right now"
/// (`activeSortSession`, and via `SortSession.lastReplay` its `ReplayEngine`) for App Intents to
/// drive from outside the view tree entirely — the exact same bridge lets this reach the same
/// state without `@FocusedValue` plumbing.
struct SortCommands: Commands {
  var body: some Commands {
    CommandMenu("Sort") {
      Button("Settings…") {
        SortCoordinator.shared.isSettingsRequested = true
      }
      .keyboardShortcut(",", modifiers: [.command])

      Button("Cycle Visualizer") {
        AppSettings.shared.cycleVisualizer()
      }
      .keyboardShortcut("v", modifiers: [.command, .shift])

      Divider()

      Button("Play/Pause") {
        guard let session = SortCoordinator.shared.activeSortSession else { return }
        session.togglePlayback()
        SortHaptics.playPauseToggled()
      }
      .keyboardShortcut(.space, modifiers: [])
      .disabled(SortCoordinator.shared.activeSortSession == nil)

      Button("Step Backward") {
        guard let replay = SortCoordinator.shared.activeSortSession?.lastReplay else { return }
        replay.pause()
        replay.stepBackward()
      }
      .keyboardShortcut(.leftArrow, modifiers: [.option])
      .disabled(SortCoordinator.shared.activeSortSession?.lastReplay == nil)

      Button("Step Forward") {
        guard let replay = SortCoordinator.shared.activeSortSession?.lastReplay else { return }
        replay.pause()
        replay.stepForward()
      }
      .keyboardShortcut(.rightArrow, modifiers: [.option])
      .disabled(SortCoordinator.shared.activeSortSession?.lastReplay == nil)

      Button("Jump to Start") {
        SortCoordinator.shared.activeSortSession?.lastReplay?.seek(to: 0)
      }
      .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
      .disabled(SortCoordinator.shared.activeSortSession?.lastReplay == nil)

      Button("Jump to End") {
        guard let replay = SortCoordinator.shared.activeSortSession?.lastReplay else { return }
        replay.seek(to: replay.totalOperationCount)
      }
      .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
      .disabled(SortCoordinator.shared.activeSortSession?.lastReplay == nil)

      Divider()

      Button("Restart") {
        guard let session = SortCoordinator.shared.activeSortSession else { return }
        Task { await session.start(size: session.arraySize) }
        SortHaptics.reset()
      }
      .keyboardShortcut("r", modifiers: [.command])
      .disabled(SortCoordinator.shared.activeSortSession == nil)

      Button("Toggle Sound") {
        SortCoordinator.shared.activeSortSession?.soundEnabled.toggle()
      }
      // Not plain ⌘A: that collides with the system's own "Select All" (⌘A is a standard
      // menu item UIKit registers automatically), which made UIMenuBuilder log a keyboard-
      // shortcut conflict and silently drop this command on Mac Catalyst.
      .keyboardShortcut("a", modifiers: [.command, .option])
      .disabled(SortCoordinator.shared.activeSortSession == nil)

      Button("Cycle Array Size") {
        guard let session = SortCoordinator.shared.activeSortSession else { return }
        Task { await session.cycleArraySize() }
      }
      .keyboardShortcut("s", modifiers: [.command])
      .disabled(SortCoordinator.shared.activeSortSession == nil)

      Divider()

      Button("Increase Speed") { bumpSpeed(by: 1) }
        .keyboardShortcut("+", modifiers: [.command, .shift])
      Button("Decrease Speed") { bumpSpeed(by: -1) }
        .keyboardShortcut("-", modifiers: [.command, .shift])
      Button("Increase Speed ×10") { bumpSpeed(by: 10) }
        .keyboardShortcut("+", modifiers: [.command, .option])
      Button("Decrease Speed ×10") { bumpSpeed(by: -10) }
        .keyboardShortcut("-", modifiers: [.command, .option])

      Divider()

      Button("Run Size Sweep") { runAutomation(.sizeSweep) }
        .keyboardShortcut("a", modifiers: [.command, .shift])
      Button("Run Max Size Only") { runAutomation(.maxSizeOnly) }
        .keyboardShortcut("a", modifiers: [.command, .option, .shift])
    }
  }

  /// Same clamp range `RunControlBar`'s speed slider enforces (1...1000) — fires a rigid haptic
  /// instead of moving `replay.speed` when the bump would have no effect, so hitting the ceiling/
  /// floor repeatedly is felt rather than silently swallowed.
  private func bumpSpeed(by delta: Double) {
    guard let replay = SortCoordinator.shared.activeSortSession?.lastReplay else { return }
    let newSpeed = min(1000, max(1, replay.speed + delta))
    if newSpeed == replay.speed {
      SortHaptics.speedClamped()
    } else {
      replay.speed = newSpeed
    }
  }

  private func runAutomation(_ id: AutomationID) {
    guard let session = SortCoordinator.shared.activeSortSession,
      let automation = AutomationRegistry.shared.automation(id: id)
    else { return }
    session.runAutomation(automation)
  }
}
