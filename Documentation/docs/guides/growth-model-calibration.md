# Recalibrating growth models

`AlgorithmMetadata.growthModel` (`OperationGrowthModel`) holds a measured curve fit to an
algorithm's actual operation-count growth, not a hand-picked guess.
`effectiveSizeRange(operationCap:)` uses this curve to compute a live, safe maximum array size per
algorithm (see
[Engine layer](../architecture/engine.md#operationgrowthmodel-and-effectivesizerange)). Run this
calibration whenever you add an algorithm, or change one enough that its operation-count growth
might have changed.

## Why a Python bridge is in the loop

`Tools/GrowthModelCalibration/` is a dev-tool only. It is never built into or shipped with the
app. Swift has no symbolic math library. One step in this pipeline requires one: fitting a curve
like `a·nᵏ·log n`, then inverting it to solve for `n` given a target operation count, has no
elementary closed-form solution. This is a case of the Lambert-*W* function family.

Rather than implementing Lambert-*W* on-device, a local HTTP bridge server (`bridge_server.py`,
loopback-only, at `http://127.0.0.1:8765`) uses SymPy to Taylor-expand the fitted curve to second
order around the measured range. This produces an ordinary quadratic, solvable at runtime with the
same closed-form quadratic solver already used for other growth-model families
(`PolynomialRootSolver` in `AlgorithmKit`).

The shipped app never talks to Python and carries no symbolic-math dependency. Only the
coefficients this bridge computes get baked into a generated Swift data literal. Every other
growth-model family the benchmark can fit has an exact closed-form inverse and never calls this
bridge.

## Running the calibration

```sh
cd Tools/GrowthModelCalibration
uv sync                     # first time only, provisions the pinned Python environment
uv run bridge_server.py     # leave running in its own terminal
```

In a second terminal:

```sh
cd Tools/GrowthModelCalibration
uv run run_calibration.py
```

This command checks the bridge server, then runs `GrowthModelCalibrationTests` through
`xcodebuild`. This is a manual-only Swift Testing suite, gated behind
`RUN_GROWTH_CALIBRATION=1` rather than a Test Plan tag, so it never runs during a normal
`xcodebuild test`. It writes `output/sort-growth-models.json`, and
`output/shuffle-growth-models.json` for shuffles; see
[Adding a shuffle](adding-a-shuffle.md#5-growth-model-calibration-is-diagnostic-only-here) for why
the shuffle output is diagnostic only.

No `--algorithm` filter is required for a normal run. The test suite resumes from the existing
JSON report and limits itself to whatever `AlgorithmID`s are new in `AllBuiltInAlgorithms.sorts`.
This is why an algorithm's registration in that file (step 2 of the porting process) must happen
before this step. While iterating on the harness itself, use
`GROWTH_CALIBRATION_ALGORITHM_FILTER`/`GROWTH_CALIBRATION_SHUFFLE_FILTER` (a substring match
against the raw ID) to narrow a run.

Once you have a fresh report, bake the fitted curve into the Swift source:

```sh
uv run apply_growth_models.py --only <algorithm-id>[,<algorithm-id>...]
```

This command edits each named algorithm's `.swift` source file directly, inserting a
`growthModel: OperationGrowthModel(...)` initializer argument computed from the calibration
report.

## A recurring bug to check for

`apply_growth_models.py`'s `insert_growth_model` inserts the new `growthModel:` argument
unconditionally, immediately after the `sizeRange:` line. It does not detect or remove a
pre-existing one. If the algorithm's source file already had a placeholder `growthModel:`
argument — for example, copied from a sibling algorithm when the file was first written — the
result is two labeled arguments to the same initializer call, which fails to compile.

Check for this immediately after running the script:

```sh
grep -n "growthModel: OperationGrowthModel(" Modules/BuiltInAlgorithms/Sources/<Category>/<AlgorithmName>.swift
```

If this command matches twice, delete the stale argument by hand before building.

## After applying the calibration

- Rebuild and retest. `apply_growth_models.py` edits Swift source directly, so this step is a
  normal compile-and-verify step, not just data generation.
- Tighten `AlgorithmMetadata.sizeRange`'s upper bound to match the calibration's measured
  safe-max-size. This matters most for an algorithm impractical past a small size. The app's
  default upper bound for most algorithms is 256. An algorithm such as Hanoi Sort or a member of
  the Bogo family needs a smaller, measured ceiling instead of that default.

See `Tools/GrowthModelCalibration/README.md` and `REPORT_FORMAT.md` for the full CLI reference and
the JSON report format.
