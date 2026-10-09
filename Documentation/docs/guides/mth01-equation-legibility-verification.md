# MTH-01 equation legibility verification

The built-in algorithm corpus has 196 detail pages. `AlgorithmDetailDataContractTests`
checks the source data for the four complexity bounds and both growth-model equations;
`GrowthModelLatexTests` checks mathematical formatting. The UI audit exercises the same
`AlgorithmDetailSection`, `LabeledEquationCell`, and chart used by the app. Its
`UI_TEST_EQUATIONS_ONLY` setting hides description prose so the equation area can be
captured at an exact 320-point detail width without changing the equation rendering path.

The 320-point audit found that the old two-column complexity grid could clip an ordinary
`O(n log² n)` equation even when the LaTeX source was short enough to omit its horizontal
scroll hint. `AlgorithmDetailSection` now stacks the five complexity cells in one column
below 500 points and retains the existing grid at wider widths. The four bounds are fully
visible in the reviewed narrow captures. Long detected and fitted equations keep their
horizontal scroll views and their scroll hints.

`AlgorithmEquationCorpusUITests` visits every page in eight shards on both platforms. It
asserts the page's unique algorithm ID, all six equation labels, and the complexity region
within the detail pane, then saves a screenshot of each page. Both runs passed 9/9 tests
with no failures or skips:

- Mac Catalyst: `/private/tmp/mth01-catalyst-corpus.xcresult`; full-resolution exports in
  `/private/tmp/mth01-catalyst-corpus-export`; 196-image contact sheets in
  `/private/tmp/mth01-catalyst-equation-sheets`.
- iPad Air 13-inch (M4), iOS 27 simulator: `/private/tmp/mth01-ipad-corpus.xcresult`;
  full-resolution exports in `/private/tmp/mth01-ipad-corpus-export`; contact sheets in
  `/private/tmp/mth01-ipad-equation-sheets`.

`contact_sheets.py --equations` verified exactly one uniquely identified screenshot for
each of the 196 pages on each platform. All ten sheets from each run were visually
reviewed for missing equations, clipping, and overlap. The four complexity bounds and
the beginning of both growth-model equations were legible throughout. Horizontal
scrolling is necessary for formulas longer than the 320-point pane.

Focused before/after UI tests verified that the long fitted formula on Introspective
Circle Sort (Recursive) moves horizontally at 320 points on both platforms
(`/private/tmp/mth01-catalyst-smoke-4.xcresult` and
`/private/tmp/mth01-ipad-scroll-320.xcresult`). A separate test uses Bogosort's long
detected equation and passed on Catalyst
(`/private/tmp/mth01-catalyst-detected-320-2.xcresult`) and iPad
(`/private/tmp/mth01-ipad-detected-320.xcresult`). The earlier 900-point fitted-equation
checks are retained in `/private/tmp/sort-contract-catalyst-equation-900.xcresult` and
`/private/tmp/sort-contract-ipad-equation-900.xcresult`.

These are simulator and Catalyst observations at the tested widths and text settings.
The retained `.xcresult` bundles and exports permit inspection of each individual page
at full resolution.
