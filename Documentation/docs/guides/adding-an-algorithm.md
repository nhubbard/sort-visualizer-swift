# Adding a sorting algorithm

This page is a working checklist. Most algorithms in this app were ported from
[ArrayV](https://github.com/gouravkhunger/ArrayV), a Java sort visualizer. See
[Port status](../reference/port-status.md) for what's shipped and what remains. The steps below
assume you are translating an existing, well-understood algorithm, not designing a new one.

## 0. Research before writing Swift

- Read the real source, not a summary. If porting from ArrayV, read
  `~/ArrayV/src/main/java/io/github/arrayv/sorts/` directly. The logic, edge cases, and any
  non-obvious bugs appear only in the source.
- Check whether the algorithm extends a shared template base class.
    - If a sibling algorithm already ported that template, reuse the pattern.
    - If several pending algorithms share one unported template, port the template once and treat
      the cluster together.
- Determine the category from the algorithm's own declared category, not from its source
  subdirectory. See `AlgorithmCategory` (`Modules/AlgorithmKit/Sources/AlgorithmMetadata.swift`)
  and match the case to what the algorithm calls itself.
- Check for anything that makes a literal, deterministic port impossible:
    - **Open-ended randomness**, such as an unseeded shuffle-until-sorted loop. `RecordingEngine`
      records a single deterministic tape, so this requires a design decision: a deterministic
      tie-break, or reuse of the primitive the native Bogo-family sorts already use. See
      `BogoSort.swift`'s doc comment for the established technique.
    - **Permutation-only preconditions**, where an algorithm is correct only when the array already
      holds a permutation of a known range. These algorithms cannot join the generic fuzz suite.
      They require a dedicated, narrower test.
    - **Correctness or stability claims that don't hold.** The source's name or comment is not
      proof. Fuzz the algorithm (step 3) before trusting any claim. Two algorithms in this app
      turned out broken or misdescribed on port: one leaves duplicates unsorted on most fuzz runs;
      another falsely claimed to be stable.
- Record the declared time complexity as a starting hypothesis for the growth-model fit in step 5,
  not as the final answer. Measure before trusting what a name or comment implies.

## 1. Write the native Swift port

Create a new file: `Modules/BuiltInAlgorithms/Sources/<Category>/<AlgorithmName>.swift`,
conforming to `SortAlgorithm`:

```swift
public protocol SortAlgorithm: Sendable {
  var id: AlgorithmID { get }
  var metadata: AlgorithmMetadata { get }
  func record(into engine: inout RecordingEngine)
}
```

Start from a structurally similar, already-shipped algorithm rather than a blank file: a
node-based tree sort, a hand-rolled heap, or whichever shape matches. Use
`engine.compare`/`engine.swap`/`engine.setValue`/`engine.values` and the rest of
`RecordingEngine`. Do not use raw Swift array mutation; the engine calls are what make the
visualizer's tape and the growth-model op-counting possible. Route any auxiliary or scratch buffer
through `engine.createAuxArray`/`writeAux`, so `auxWriteCount` reflects it. See
[Engine layer](../architecture/engine.md#recordingengine) for the full `RecordingEngine` surface.

Fill in `AlgorithmMetadata`'s fields:

- `displayName`, `category` (see step 0).
- `sizeRange`: start conservative. Calibration in step 5 sets the real bounds.
- `stable`, `timeComplexity`, `spaceComplexity`, `iconName`.
- `growthModel`: leave as a placeholder. Step 5 overwrites it mechanically. Do not hand-tune
  coefficients here.

In the doc comment, explain why the port works the way it does: what invariant makes it safe, what
differs from the source, and why. Do not narrate what each line does.

## 2. Register the algorithm at three call sites

All three lists are alphabetized `SortAlgorithm()` instantiations. Add the new algorithm in
alphabetical order in each:

1. `App/Sources/Sort2App.swift` (`AlgorithmRegistry.shared.builtIns`).
2. `Modules/BuiltInAlgorithms/Tests/Support/AllBuiltInAlgorithms.swift`.
3. `Modules/BuiltInAlgorithms/Tests/NativeAlgorithmCorrectnessTests.swift`'s `Self.algorithms`
   list. If the algorithm cannot safely join the generic fuzz suite (a permutation-only
   precondition; see step 0), omit it here and write a dedicated test instead.

Verify by grepping for `<AlgorithmName>()` across the repository. It should match exactly these
three files plus the new source file. A missing first site breaks the app. Missing the other two
does not break the build, but it silently drops the algorithm from the generic fuzz suite and from
growth-model calibration, since calibration reads `AllBuiltInAlgorithms.sorts` directly.

## 3. Fuzz before trusting the port

Run the project's fuzz tests against the new algorithm specifically:

- Random inputs.
- Duplicate-heavy inputs.
- Already-sorted inputs.
- Reverse-sorted inputs.
- The stability claim recorded in `AlgorithmMetadata.stable`.

Fuzz every algorithm, including ones that look straightforward. Step 0 lists two algorithms that
looked ordinary and were not. If the fuzz run finds a problem, fix the port or the metadata before
proceeding to content and calibration.

## 4. Write the ten-language content bundle

See [Managing algorithm content](algorithm-content.md) for the full `manage.py` workflow:
scaffold, hand-write `description.md` and ten language samples, test, lint and format, highlight,
then pack. Do not reference ArrayV or any other porting source in the reference implementations or
in `description.md`. This content ships as this project's own original reference material.

## 5. Calibrate the growth model

See [Recalibrating growth models](growth-model-calibration.md) for the full workflow:

```sh
cd Tools/GrowthModelCalibration
uv run run_calibration.py
uv run apply_growth_models.py --only <algorithm-id>
```

Watch for a known, recurring bug: `apply_growth_models.py` inserts a new `growthModel:` argument
unconditionally after `sizeRange:`. It does not detect or remove a pre-existing placeholder from
step 1. If the source file already had a `growthModel:` argument, the result is two labeled
arguments to the same initializer call, which fails to compile. After running
`apply_growth_models.py`, grep the touched file for a duplicate
`growthModel: OperationGrowthModel(` and delete the stale one by hand.

After calibration reports a measured safe-max-size, tighten `sizeRange`'s upper bound to match.
This matters most for an algorithm impractical past a small size. The app's default upper bound is
256; an algorithm such as Hanoi Sort needs a smaller, measured ceiling.

## 6. Close out the port tracker

If you track work against [Port status](../reference/port-status.md), remove the shipped
algorithm's line from its category's remaining list once it ships. Delete on ship; do not archive
with a note. If the algorithm was the last member of an effort tier or cluster, remove the
now-empty heading too.

## 7. Verify before finishing

- Run the full build and test suite for the affected targets: `BuiltInAlgorithms` and the app
  target.
- Check `git status`/`git diff --stat` before committing. Expect the new source file, the three
  registration call sites, `AlgorithmDetails.algz` plus the new content folder, the calibration
  tool's output JSON, and the port tracker if you maintain it.
