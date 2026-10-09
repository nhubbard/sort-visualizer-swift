# REF-01 reference content verification

The detail pane loads a selected algorithm's description and ten-language reference samples
from the bundled `AlgorithmDetails.algz` archive. Complexity labels and equations come from
algorithm metadata; the store and notation tests cover archive decoding and equation inputs.

`ReferenceContentUITests` follows the normal sidebar to Quick Sort. It checks selected prose,
the complexity grid and its four labeled cases, the rendered Python reference source, and a
change to the Swift source after selecting Swift in the language picker. Its failure journey
sets `UI_TEST_MISSING_ALGORITHM_DETAILS=1`, which makes the debug archive loader throw the same
`archiveResourceNotFound` error as a missing bundle resource. The detail pane then shows a
reinstall instruction instead of treating a damaged archive as an algorithm with no authored
description. Metadata-based complexity remains visible. The UI test hook does not alter the
signed archive on disk and is absent from release builds.

The detail pane now shows loading indicators while its archive resolves. The store distinguishes
a valid archive with no entry for an algorithm from an archive load failure, and its unit tests
pin that distinction.

Results:

- iPad Air 13-inch (M4), iOS 27 simulator:
  `/private/tmp/ref01-ipad-final.xcresult`, 2 passed, 0 failed, 0 skipped.
- Mac Catalyst: `/private/tmp/ref01-catalyst-final.xcresult`, 2 passed, 0 failed, 0 skipped.
- `SortFeature` archive and store tests: `/private/tmp/ref01-sortfeature.xcresult`, 10 passed.
- `MathRenderingKit` notation tests: `/private/tmp/ref01-math.xcresult`, 11 passed.

The UI asserts the selected complexity section and labels. Short equations are not exposed as
scroll views in Catalyst's accessibility tree when they fit; individual equation appearance
and narrow-window legibility remain part of MTH-01's visual review.
