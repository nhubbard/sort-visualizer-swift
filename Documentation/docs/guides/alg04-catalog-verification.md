# ALG-04 catalog verification

The checked-in catalog gate is `App/UITests/CatalogCompletenessUITests.swift`. It launches the
real app, scans the SwiftUI algorithm list while scrolling, compares the collected IDs with the
independent 196-ID snapshot in `CatalogExpectedIDs.swift`, checks the ten sidebar categories in
order, and checks the Quick category's two visible algorithms. A second launch sets
`UI_TEST_REMOVED_ALGORITHM_ID=quicksort`, which removes that registration before discovery, and
asserts that the visible list contains exactly the other 195 IDs. The launch variable is used
for catalog verification; production launches leave it unset.

On 2026-10-03, the iPad (A16) iOS 27 simulator ran both UI tests successfully in
`/private/tmp/sort-contract-alg04-ipad.xcresult`. The iOS 27 App Intents system suite passed
16/16 in `/private/tmp/sort-contract-alg04-intents.xcresult`, including exact algorithm and
shuffle counts. Catalyst registry tests passed 6/6 in
`/private/tmp/sort-contract-alg04-registry.xcresult`; the native catalog assertion passed in
`/private/tmp/sort-contract-alg04-corpus-final.xcresult`.

The Mac Catalyst XCTest runner on this host timed out while enabling automation mode, both
without signing and with the local Apple Development identity. To verify the Catalyst UI outcome,
the built app was launched directly twice and inspected through its macOS accessibility tree.
The scanner located `algorithmContentList`, collected button identifiers beginning with
`algorithmLink.`, scrolled by half-page increments to expose virtualized rows, and stopped at the
end of the list. The ordinary launch yielded 196 distinct IDs, including `quicksort`. The launch
with `UI_TEST_REMOVED_ALGORITHM_ID=quicksort` yielded 195 distinct IDs. Their set difference was
exactly `quicksort`; neither scan contained an extra ID relative to the other. The sorted normal
ID set matched the independent UI fixture (FNV-1a 32-bit hash of comma-joined IDs: `1827002513`).
The visible Quick category contained exactly `ternaryllquicksort` and `ternarylrquicksort`.

When macOS automation access is available to Xcode's Catalyst test runner, run the same checked-in
UI tests with the `Sort SymphonyUITests` scheme on the Mac Catalyst destination. The direct
accessibility scan verifies the current Catalyst build, while that repeatable XCTest run will
provide a result bundle for future changes.
