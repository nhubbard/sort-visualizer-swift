# Growth model calibration report format

This describes `output/sort-growth-models.json` and `output/shuffle-growth-models.json`,
produced by `GrowthModelCalibrationTests.swift` (`Modules/BuiltInAlgorithms/Tests/`). Each file is
a flat JSON array of report objects — one per subject profiled.

## Background: what's being measured

The app caps how many primitive operations (compares, swaps, writes — a `RecordingEngine`'s
`tape`) a single sort/shuffle recording may contain, since that tape has to fit in memory and
play back at a reasonable pace. Each algorithm's `sizeRange` upper bound is supposed to keep it
under that cap, but those bounds were originally hand-guessed. This benchmark instead:

1. Actually runs each algorithm (and shuffle) at a sequence of array sizes `n`, counting
   operations for real.
2. Fits a mathematical growth model to those measurements (see "Growth families" below).
3. Solves that model for the largest `n` that stays under a given operation cap, with a 20%
   safety margin baked in (it solves for 80% of the cap, not 100%).
4. Verifies the answer by evaluating the model back against the cap and backing off if needed.

The "operation count" measured throughout is a **tape-size estimate**, not the raw comparison
count: `5×(compares + swaps) + setValues + auxWrites + reversals`. The `5×` factor on compares/
swaps accounts for the marker-highlighting bookkeeping (`RecordingEngine.markPrimarySecondary`)
that piggybacks on every one of those calls in the real recorded tape.

## Two files, two kinds of subject

- **`sort-growth-models.json`**: one entry per built-in *sort* algorithm. Sorts are profiled
  against all 38 registered shuffles independently (a sort's real growth can depend heavily on
  which shuffle produced its input — see `subjectID` below) and only the **binding** (most
  restrictive) shuffle's result is kept.
- **`shuffle-growth-models.json`**: one entry per built-in *shuffle*. Shuffles are profiled
  standalone, starting from an identity (sorted) array — no sort involved.

Both files are a flat JSON array of report objects, sorted alphabetically by `subjectID` — this
sorting happens on every write (not just once), so re-running calibration for one algorithm only
ever changes that algorithm's own entry in a diff, never the position of any other entry.

## Field reference

| Field | Type | Meaning |
|---|---|---|
| `subjectID` | string | `shuffle-growth-models.json`: the shuffle's own ID (e.g. `"random"`). `sort-growth-models.json`: `"<algorithmID>+<bindingShuffleID>"` (e.g. `"mergesort+descending"`) — the shuffle named is whichever of the 38 tested shuffles produced the *smallest* safe size for this algorithm, i.e. the worst case a user could actually hit by picking that shuffle. |
| `winningFamily` | string | Which growth-model shape best fit the measured data. One of `powerLaw`, `powerLog`, `polynomialIntercept`, `exponential`, `nToTheNLike`, `factorial` — see "Growth families" below. |
| `winningRSquared` | number | Coefficient of determination (0–1) of the winning fit, computed on real operation-count values (not the log-transformed space the regression itself ran in). Closer to 1 is a tighter fit. |
| `runnerUpFamily` / `runnerUpRSquared` | string? / number? | The second-best family and its R², included so a human can sanity-check close calls. `null` if only one family had enough data to fit at all. |
| `coefficients` | number array | The winning family's fitted parameters — **what they mean depends on `winningFamily`**, see the table below. |
| `sampleSizes` | integer array | The actual array sizes (`n`) that were measured (not predicted/skipped) to produce this fit. |
| `safeMaxSizeByCap` | object (see caveat below) | The computed max safe array size at three reference operation caps: 100,000 / 300,000 / 1,000,000. A cap missing from this map means no positive solution was found — see "No entry for a cap" below. |
| `unsafeAtSize` | integer? | Present only if measurement stopped early because of a detected problem at this array size (see `unsafeReason`). Every `safeMaxSizeByCap` value is already clamped below this size — it's kept here so you can see *why* a result looks more conservative than the curve alone would suggest, and to flag algorithms that need a real bug fixed. |
| `unsafeReason` | string? | `"hang"` — a trial at `unsafeAtSize` genuinely never returned (8× the per-trial time budget elapsed with no result). Very likely a real non-terminating bug in that specific algorithm/shuffle combination, not just slowness. `"erratic jump"` — the measured value at `unsafeAtSize` was 100×+ larger than the established trend from smaller sizes predicted. Not a hang, but a sign of genuinely discontinuous/unpredictable behavior (that data point is excluded from the fit entirely, not just capped around). |

### ⚠️ `safeMaxSizeByCap`'s actual JSON encoding

Swift's `Codable` only produces a normal `{"key": value}` JSON object for dictionaries keyed by
`String` or `Int`. This dictionary is keyed by `Double` (100000.0 / 300000.0 / 1000000.0), so it
serializes as a **flat array of alternating key, value, key, value, ...**, always ascending by
cap (`GrowthReport.encode(to:)` sorts explicitly before writing — `Dictionary`'s own iteration
order for a `Double` key is randomized per process, which otherwise perturbed every algorithm's
entry on every calibration run, not just the one actually re-measured):

```json
"safeMaxSizeByCap": [100000, 7, 300000, 7, 1000000, 7]
```

Read it in pairs: `(100000 → 7)`, `(300000 → 7)`, `(1000000 → 7)`. In Python:

```python
caps = data["safeMaxSizeByCap"]
cap_map = {caps[i]: caps[i + 1] for i in range(0, len(caps), 2)}
```

### No entry for a cap

If a particular cap value (say 1,000,000) doesn't appear as a key at all, it means the fitted
curve never produces a valid solution for it — usually because growth is so flat/negligible
(e.g. `AscendingShuffle`, which does almost nothing since the array's already sorted) that no
reasonable array size would ever reach that many operations, or because the fit itself was too
degenerate to trust (rare — most degenerate fits are rejected before ever producing a report; see
"Data quality guarantees" below). This is a normal, expected outcome, not an error — there is
deliberately no `-1` or other numeric sentinel for it, so don't treat a missing key as zero.

## Growth families and their coefficients

Each family is a fitted curve `T(n)` (predicted operation count at array size `n`). `n` and `T`
are always positive in practice.

| `winningFamily` | Formula | `coefficients` |
|---|---|---|
| `powerLaw` | `T = a·nᵏ` | `[a, k]` |
| `powerLog` | `T = a·nᵏ·log(n)` | `[a, k]` |
| `polynomialIntercept` | `T = a·n² + b·n + c` | `[a, b, c]` |
| `exponential` | `T = a·bⁿ` | `[a, b]` |
| `nToTheNLike` | `T = a·exp(c·n·log(n))` (equivalently `a·n^(c·n)`) | `[a, c]` |
| `factorial` | `T = a·exp(c·(n·log(n) − n))` (Stirling's approximation of `n!`, generalized with a free rate `c`) | `[a, c]` |

`log` is the natural logarithm throughout. To reproduce `safeMaxSizeByCap` yourself: solve
`T(n) = 0.8 × cap` for `n` (the 20% safety margin — see "Background" above), then round down.

## Data quality guarantees

The benchmark applies several checks *before* a fit is ever reported, so — barring a bug not yet
found — everything in these files should already satisfy:

- **No overfitting from sparse data**: every family requires at least 2 more usable data points
  than it has free parameters (2 for most families, 3 for `polynomialIntercept`). A 3-parameter
  model fit to only 4 points, for instance, is never reported even if it scores a high R² —
  model selection actually uses *adjusted* R² internally for exactly this reason, though the
  plain `winningRSquared`/`runnerUpRSquared` fields report the unadjusted value.
- **Monotonicity**: every reported fit's `T(n)` is verified non-decreasing from `n = 1` out to
  100× the largest measured sample. A curve that predicts *fewer* operations for a *larger* array
  is rejected outright, however well it scores on the sampled points.
- **Hang/erratic-jump awareness**: see `unsafeAtSize`/`unsafeReason` above.

## `unsafeReason` flags in this data (as of this run)

Only one subject in the current data is flagged: `cocktailbogosort+finalradix` (`erratic jump` at
size 14). That's expected, not a bug — `CocktailBogoSort` is a genuinely `O(n·n!)`-family
"Impractical Sort" (a deterministic permutation walk), and the real jump between its `n=7` and
`n=14` measurements reflects true factorial blowup (`14!/7! ≈ 17 million×`) outrunning a curve
fitted to just 4 small points, not a measurement artifact.

Two other classes of finding surfaced and were resolved earlier in this data's history, in case
you're comparing against an older copy of these files:

- **A real algorithm bug**: `MergeBogoSort` had a genuine infinite loop for any top-level array
  size past 64 (a 64-bit bitmask couldn't represent its merge-weave interleaving beyond that
  width). Fixed by replacing the bitmask enumeration with an explicit lexicographic-combination
  walk — `mergebogosort` now measures cleanly (see its entry above) instead of hanging.
- **A harness bug, not an algorithm bug**: several perfectly healthy algorithms (`RecursiveShellSort`,
  `ShellSort`, `RotateMergeSort`, `SwaplessBubbleSort`, `OptimizedCocktailShakerSort`,
  `MergeExchangeSortIterative`, `LLQuickSort`, `IntroSort`, `DualPivotQuickSort`, and the
  `HalfRotation` shuffle) were previously misflagged `erratic jump` — caused by the harness's own
  size-extrapolation predictor collapsing toward zero when two small, noisy early measurements
  happened to decrease before growth kicked in. Fixed in the harness itself (the extrapolation
  ratio is now floored at 1.0, since operation counts don't shrink as `n` grows); none of those
  algorithms needed any code change.
- `BozoSort`, `StablePermutationSort`, `DeterministicBogoSort`, `SmartBogoBogoSort`, and
  `MedianQuickBogoSort` are all, like `CocktailBogoSort`, genuinely correct `O(n·n!)`-family
  algorithms — their worst-case (binding) shuffle in this data now happens to be one where the
  harness's predictive safety gate stopped growth *before* attempting a catastrophic size, so
  none of them show an `unsafeReason` flag at all in this run, but don't read that as "these grow
  reasonably" — `sampleSizes` for all of them tops out at `n=7` for exactly this reason.
