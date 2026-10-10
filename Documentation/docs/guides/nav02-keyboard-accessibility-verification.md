# NAV-02 keyboard and accessibility verification

The active sort's transport is exposed as five labeled buttons in visual order: Jump to Start,
Step Back, Play or Pause, Step Forward, and Jump to End. The playback slider announces its
operation position on iPad. The size and speed disclosures announce their current values.
The status text continues to expose the session phase and correctness value. The existing
`RunControlBarUITests` exercise the scrub slider, transport, sizing, and playback actions.

`NavigationAccessibilityUITests.testTransportAnnouncesStateAndAccessibleActionsWork` launches
the app, selects Quick Sort through the real sidebar, pauses and rewinds playback, and checks
the transport's accessibility tree order, labels, and state values. It steps forward and back
to prove the actions change the active replay and toggles the sound control through its
accessible button. This checks the accessibility tree's order as a proxy for VoiceOver focus
order; it does not automate the VoiceOver rotor or speech engine.

Results:

- iPad Air 13-inch (M4), iOS 27 simulator, default content size:
  `/private/tmp/nav02-ipad-3.xcresult`, 1 passed, 0 failed.
- Same simulator with `simctl ui <device> content_size accessibility-medium` confirmed before
  the run: `/private/tmp/nav02-ipad-large-accessibility.xcresult`, 1 passed, 0 failed. The
  transport remains reachable and functional at enlarged text size.
- Mac Catalyst: `/private/tmp/nav02-catalyst-2.xcresult`, 1 passed, 0 failed. Catalyst's native
  slider reports a numeric accessibility value, so the exact spoken operation-position value is
  asserted only on iPad. Its label, order, and actions are asserted on Catalyst.
- Existing Catalyst Sort command actions: `/private/tmp/nav02-catalyst.xcresult`, 3 passed. The
  fourth test in that bundle was the initial accessibility assertion against the Catalyst
  slider's value; it was corrected and rerun in the passing bundle above.
- Direct Catalyst shortcut check on the same built app: after selecting Quick Sort and pausing
  playback, sending `⌘⌥A` to the foreground app changed the accessible sound action from
  `Mute` to `Unmute`. This checked the key binding itself, beyond clicking its Sort menu action.

The iPad UI runner disconnected while an XCTest test injected the `⌘⌥A` shortcut, including
after playback was paused before injection. Those attempts did not produce a usable result
bundle. The command action itself is covered through the Catalyst Sort menu test, and the
same sound action is checked from the iPad accessibility button. The simulator key-injection
result is not evidence that a physical iPad keyboard shortcut works or fails. The shortcut is
declared in the scene's `CommandMenu`, which [Apple documents as creating iPadOS key commands
for items with keyboard shortcuts](https://developer.apple.com/documentation/swiftui/commandmenu).
The user accepted this simulator limitation for NAV-02 closure on 2026-10-04.
