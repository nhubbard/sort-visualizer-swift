# Accessibility and design audit: working findings

Started 2026-10-06. This is a source review, focused platform audit, and first batch of fixes. A complete manual VoiceOver and Human Interface Guidelines (HIG) review still needs the journeys listed below. The broader scope and effort estimate are in [NEXT_STEPS.md](../../../NEXT_STEPS.md).

## Baseline

- The existing [NAV-02 verification](nav02-keyboard-accessibility-verification.md) checks transport order, labels, values, and actions on iPad and Catalyst. It explicitly uses the accessibility tree as a proxy; it does not verify VoiceOver speech or rotor behavior.
- The current test corpus covers many navigation and settings outcomes. An accessibility identifier lets a test locate a control, but it does not establish a useful spoken name, value, or hint.
- The app uses a `NavigationSplitView`, a custom Metal canvas, Swift Charts, expandable playback controls, and a long-form home page. Those are the first journeys to inspect with assistive technology and at narrow widths.

## Findings and changes in this pass

| ID | Evidence and HIG concern | Action | Verification |
| --- | --- | --- | --- |
| A11Y-01 | `RandomizingHeader` replaced the visible title with shuffled characters 48 times on appearance and tap. It had no stable spoken label and used a fixed font. Xcode's Dynamic Type audit identified individual header glyphs as unsupported. | Shuffle once per appearance or activation, then replay a paced Quick Sort on every setting. Compare and swap colors mark the active letters. Reduce Motion keeps the algorithm and pacing but removes spatial swap animation. Draw the visual glyphs in SwiftUI Canvas with the original 48-point bold system style, proportionally spaced and scaled relative to Dynamic Type's large-title style; expose one stable spoken button name and hint. | Two `HeaderQuickSort` unit tests passed, including duplicate letters and all permutations of six indices. Catalyst screenshot confirms the paced colored letters and its accessibility tree exposes one button named “SORT SYMPHONY.” The focused Dynamic Type UI audit passed on Home and Sort after the typography adjustment. |
| A11Y-02 | The inline playback-speed and target-duration sliders were constructed without explicit labels. The nearby “Slow/Fast” and “1s/120s” text describes endpoints but does not give the slider a clear spoken purpose. | Add spoken names and units; assert them in the existing iPad UI journeys. | Focused iPad UI run passed all three selected tests, including both slider journeys. Catalyst app build passed. |
| A11Y-03 | The Metal visualization was absent from the Catalyst accessibility tree, so a nonvisual user could reach the transport but not its subject. Continuous speech for every operation would overwhelm the user on long or fast tapes. | Expose the Metal view as one image-like accessibility element with item count and visualizer name. Speak the operation after a manual forward step, and announce the new position for back and jump actions when VoiceOver is enabled. The accessible scrub slider already reports operation position. | Catalyst accessibility tree now shows “Sort visualization,” “240 items, Sine Wave,” then transport controls. Focused SortFeature tests passed. Manual VoiceOver speech and iPad tree check remain. |
| DESIGN-01 | The home copy instructed users to choose an algorithm from the “sidebar on the left,” even though compact navigation need not present a left sidebar. Apple's layout guidance asks content to adapt to the available window. | Refer to the algorithm catalog instead of a physical position. | Catalyst app build passed. Compact-layout visual review remains. |
| A11Y-04 | Xcode's `.textClipped` audit on iPad reported the sidebar's “All Algorithms” label, then the search placeholder, then even the shortened “All” label at its extreme text-size setting. | Use shorter visible category names while preserving full spoken names. Shorten the search placeholder. Keep the clipping issue open for visual review of the sidebar at accessibility sizes; the last report could reflect native List row geometry. | The combined audit is still red on iPadOS 27.0, including after shortening the row label. The separate Dynamic Type audit passed on Home and Sort. |

The selected iPad UI result is `/private/tmp/sort-accessibility-focused.xcresult`: 3 passed, 0 failed, 0 skipped on iPad Air 13-inch (M4), iOS 27.0. It covered the live speed slider, fixed-duration slider, and existing transport accessibility journey. The header algorithm tests are in `/private/tmp/sort-header-quicksort.xcresult`: 2 passed. The focused Home and Sort Dynamic Type UI audit passed after restoring the original typography; its log is `/private/tmp/sort-header-restyle-dynamic-type.log`. The initial Xcode Dynamic Type issue screenshot and description are in `/private/tmp/sort-audit-attachments/`. Logs for subsequent combined audit runs are `/private/tmp/sort-dynamic-type-audit-{7,8,9,10}.log`; they show the transition from header font issue to sidebar clipping. Catalyst's live accessibility tree confirmed the canvas and title labels. These checks do not amount to manual VoiceOver speech verification.

## Next checks

1. Run the app with VoiceOver enabled and Accessibility Inspector. Check the home title, catalog search/results, transport and expanded sliders, Metal visualization description, chart exploration, and settings. Repeat with Dynamic Type settings changed and with Reduce Motion enabled.
2. Review the same journeys on Catalyst with VoiceOver and Full Keyboard Access. Confirm focus order after opening and closing inline controls, sheets, and menus.
3. Inspect the `.textClipped` sidebar report visually at accessibility text sizes, then run the platform audit on the remaining representative screens. Audit findings can include framework-generated false positives.
4. Review the HIG's layout, navigation, toolbar, controls, onboarding, and feedback guidance against screenshots at compact and wide widths. Record concrete reproduction and severity before making larger design changes.
5. Check whether the canvas summary plus spoken manual steps make a sorting run understandable with VoiceOver. Give charts a similar nonvisual review; the existing chart accessibility tree offers series and ranges, but its usefulness has not been confirmed by listening.

## References

- [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Apple HIG: Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Apple: Performing accessibility testing](https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app)
