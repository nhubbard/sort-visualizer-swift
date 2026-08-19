# Adding a shuffle

A `ShuffleAlgorithm` shares its primitive surface with `SortAlgorithm`: it records against the
same `RecordingEngine`, starting from a sorted identity array. Most of
[Adding a sorting algorithm](adding-an-algorithm.md) applies here, against a smaller metadata
surface and without a per-algorithm content bundle. This page covers only the differences. Read
the algorithm guide first.

## What's smaller here

```swift
public protocol ShuffleAlgorithm: Sendable {
  var id: ShuffleID { get }
  var metadata: ShuffleMetadata { get }
  func record(into engine: inout RecordingEngine)
}

public struct ShuffleMetadata: Sendable, Codable, Equatable {
  public var displayName: String
}
```

`ShuffleMetadata` has no category, size range, growth model, complexity strings, or icon. A user
picks a shuffle by name from a flat list (`ShuffleRegistry.shared.shuffles`), not from a category
sidebar the way algorithms are organized.

## 1. Write the native Swift port

Create a new file: `Modules/BuiltInAlgorithms/Sources/Shuffles/<ShuffleName>.swift`. Start from an
existing shuffle with a similar shape. Structured shuffles (radix, bitonic, merge, BST-traversal,
Sierpinski) differ meaningfully from a plain randomized shuffle; pick a real precedent rather than
starting blank.

The deterministic-recording constraint from the algorithm guide applies here too. A
`RecordingEngine` records one deterministic tape, so unbounded randomness has no meaning. Every
built-in shuffle resolves this with a seeded or otherwise deterministic approach. Check
`RandomShuffle.swift` and a structured shuffle such as `RecursiveRadixShuffle.swift` for the two
ends of that spectrum.

Two shuffles, `ShuffledCubicShuffle` and `ShuffledQuinticShuffle`, resample through a skewed curve
and can legitimately produce duplicate values instead of a strict permutation. If your shuffle does
this, document it in the doc comment. This affects which correctness test category it belongs in
(see step 3).

## 2. Register the shuffle at two call sites

Shuffles do not need the dedicated-correctness-list distinction algorithms have, but they require:

1. `App/Sources/Sort2App.swift` (`ShuffleRegistry.shared.builtIns`), alphabetized like the
   algorithm list.
2. `Modules/BuiltInAlgorithms/Tests/Support/AllBuiltInAlgorithms.swift`'s `shuffles` array, read by
   the growth-model calibration sweep and other test fixtures that enumerate every shuffle this
   app ships.

## 3. Correctness testing has two tiers

`Modules/BuiltInAlgorithms/Tests/NativeShuffleCorrectnessTests.swift` checks two properties. Which
list your shuffle belongs in depends on what it guarantees:

- **Every shuffle** belongs in the length-preservation check. This check is inexpensive.
- **Shuffles that only rearrange existing values** — most of them — also belong in
  `permutingShuffles`, a stronger check confirming the output is a genuine permutation of the
  input, not just a same-length array. Omit a shuffle from this list only if it can legitimately
  produce duplicates or drop values by design, and document why.
  `LogarithmicSlopesShuffle`'s exclusion comment is a model example: its index formula reads some
  low indices repeatedly by construction, a property of the formula, not a bug.

Fuzz the shuffle the same way you fuzz an algorithm (step 3 of the algorithm guide) before trusting
either claim.

## 4. Skip the content bundle

Shuffles do not get a folder under `App/Resources/AlgorithmDetails/`, a `description.md`, or
ten-language code samples. No shuffle detail screen equivalent to `AlgorithmDetailSection` exists.
Skip [Managing algorithm content](algorithm-content.md) entirely for a shuffle-only change.

## 5. Growth-model calibration is diagnostic only here

`GrowthModelCalibrationTests.calibrateShuffles()` measures and reports a growth curve per shuffle,
written to `Tools/GrowthModelCalibration/output/shuffle-growth-models.json`. Unlike a sort
algorithm's `growthModel`, nothing in `ShuffleMetadata` consumes this output. It exists for manual
inspection — for example, to decide whether a shuffle is expensive enough to worry about at large
array sizes. It is not baked into shipped code the way
[Recalibrating growth models](growth-model-calibration.md) describes for algorithms. Running it
for a new shuffle is optional.

## 6. Verify before finishing

Follow the same shape as the algorithm guide: run the full build and test suite for
`BuiltInAlgorithms` and the app target, then check `git status`/`git diff --stat`. Expect only the
new source file and the two registration sites, with no content-bundle or calibration-JSON
changes.
