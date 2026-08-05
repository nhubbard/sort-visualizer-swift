# Algorithm Porting Process

End-to-end checklist for taking one ArrayV sorting algorithm from "not started" in
`PORT_INVENTORY.md` to a fully shipped, tested, documented, calibrated algorithm. Written up after
the Patience/Splay/Tree-sort batch (`a2c0da7`) and the distribution/merge batch made the same
mistakes worth writing down once. If a step below turns out stale (a script gets renamed, a call
site moves), fix this file in the same commit — it's a process doc, not a historical record.

## 0. Research the source

- Read the algorithm's real Java source under `~/ArrayV/src/main/java/io/github/arrayv/sorts/`,
  not just `PORT_INVENTORY.md`'s one-line summary — line counts and effort tiers there come from
  this source, but the actual logic, edge cases, and any non-obvious bugs only show up by reading
  it.
- Check whether it `extends` one of the shared `sorts/templates/` base classes. If a sibling
  algorithm already ported that template, reuse the pattern; if not and multiple pending
  algorithms share one, port the template once and treat the cluster together (see
  `PORT_INVENTORY.md`'s cluster notes for precedent).
- **Category comes from the algorithm's own `setCategory(...)` call, not from which
  `sorts/<dir>/` it physically lives in.** ArrayV itself sometimes disagrees with its own directory
  layout (e.g. `HanoiSort` lives in `sorts/insert/` but calls `setCategory("Impractical Sorts")`).
  `AlgorithmCategory` (`Modules/AlgorithmKit/Sources/AlgorithmMetadata.swift`) has one case per real
  ArrayV category — pick whichever one actually matches the `setCategory` string.
- Look for anything that makes a literal port impossible in this engine:
  - **Nondeterminism** (`java.util.Random`, unseeded shuffles) — `RecordingEngine` records a
    single deterministic tape, so an open-ended random choice has no meaning here. Needs a
    deliberate design decision (deterministic tie-break, or reuse whatever primitive the native
    shuffles already use for controlled randomness) — see `BogoSort.swift`'s doc comment and the
    Library Sort precedent for how this was resolved.
  - **Permutation-only preconditions** (e.g. `IndexSort` — only correct when the array already
    holds a permutation of `min...(min+n-1)`). These can't join the generic fuzz suite in
    `NativeAlgorithmCorrectnessTests.swift`; they need their own narrower test instead.
  - **Correctness/stability claims that don't actually hold** — ArrayV's own name or comment is
    not proof. `FunSort` and `StablePermutationSort` both turned out to be wrong when fuzzed. Never
    skip step 3 below because the algorithm "obviously" behaves a certain way.
- Note the declared `timeComplexity` — it's a starting hypothesis for the growth-model fit, not the
  final answer (see the `InPlaceLSDRadixSort`/`BufferedStoogeSort` precedent: measure before
  trusting what the name/complexity claim implies).

## 1. Write the native Swift port

- New file: `Modules/BuiltInAlgorithms/Sources/<AlgorithmName>.swift`, conforming to
  `SortAlgorithm` (`AlgorithmKit`). Look at a structurally similar already-shipped algorithm first
  — e.g. `TreeSort.swift`/`SplaySort.swift` for node-based trees (index-`pointer` nodes vs.
  held-`key` copies, rotation helpers), `PatienceSort.swift` for a hand-rolled heap.
- `AlgorithmMetadata` fields to fill in: `displayName`, `category` (see step 0), `sizeRange`
  (start conservative — actual bounds come from calibration in step 4), `stable`, `timeComplexity`,
  `spaceComplexity`, `iconName`. Leave `growthModel` as a reasonable placeholder; it gets
  overwritten mechanically in step 4 — don't hand-tune coefficients here.
- Use `engine.compare`/`engine.setValue`/`engine.values` etc. from `RecordingEngine`, not raw
  Swift array mutation — this is what makes the visualizer's tape and the growth-model op-counting
  possible. Auxiliary data structures (stacks, external buffers) should route their writes through
  the engine's aux-write tracking so `auxWriteCount` reflects them, matching how `mainWriteCount`/
  `auxWriteCount` are already used elsewhere.
- Doc comment: explain *why* the port works the way it does (what invariant makes it safe, what
  differs from ArrayV and why), not what each line does line-by-line — match the style already in
  `TreeSort.swift`/`SplaySort.swift`.

## 2. Register the algorithm (3 call sites)

All three lists are alphabetized `SortAlgorithm()` instantiations — add the new one in alphabetical
order in each:

1. `App/Sources/Sort2App.swift`
2. `Modules/BuiltInAlgorithms/Tests/Support/AllBuiltInAlgorithms.swift`
3. `Modules/BuiltInAlgorithms/Tests/NativeAlgorithmCorrectnessTests.swift`'s own private
   `Self.algorithms` list

Verify by grepping for `<AlgorithmName>()` across the repo — it should hit exactly these three
files (plus the new source file itself). Missing site 1 breaks the app; missing sites 2/3 doesn't
break the build, it just silently drops the algorithm from the generic fuzz suite and/or the
growth-model calibration sweep (calibration reads `AllBuiltInAlgorithms.sorts`).

If the algorithm can't safely join the generic fuzz suite (permutation-only precondition, see step
0), leave it out of `NativeAlgorithmCorrectnessTests.swift`'s `Self.algorithms` and write a
dedicated test instead.

## 3. Fuzz before trusting it

Run the project's fuzz tests against the new algorithm specifically — correctness (random inputs,
duplicate-heavy inputs, already-sorted inputs, reverse-sorted) and the stability claim you wrote
into `AlgorithmMetadata.stable`. Do this for every algorithm, not just the ones that "look" tricky
— `FunSort` (ArrayV's own class leaves duplicates unsorted ~84% of the time) and
`StablePermutationSort` (falsely claimed stable, ~40% fuzz failure) both looked like ordinary ports
until fuzzed. If the fuzz run finds the algorithm is broken or misdescribed, fix the port or the
metadata now, before moving on — don't discover it after the content bundle and calibration are
already done.

## 4. Ten-language content bundle (`App/Resources/AlgorithmDetails/`)

See `App/Resources/AlgorithmDetails/README.md` for the full `manage.py` reference; the short
version:

```sh
cd App/Resources/AlgorithmDetails
uv run manage.py scaffold <algorithm-id>       # creates <algorithm-id>/ from template/
# hand-write <algorithm-id>/description.md and <algorithm-id>/<algorithm-id>.{c,cpp,cs,go,java,js,kt,py,rb,swift}
uv run manage.py test <algorithm-id>           # compiles/runs every language, checks sorted output
uv run manage.py lint <algorithm-id> --fix      # per-language linters; needs `manage.py setup` once
uv run manage.py format <algorithm-id>          # per-language formatters
uv run manage.py highlight <algorithm-id>       # REQUIRED before pack — generates <lang>.md files
uv run manage.py pack                           # rebuilds AlgorithmDetails.algz for ALL algorithms
uv run manage.py decode <algorithm-id>          # optional: sanity-check the packed byte layout
```

Notes:
- **`highlight` must run before `pack`** — `pack` only compresses `description.md` and the
  generated `<lang>.md` files, not the raw `.{c,cpp,...}` sources. Skipping `highlight` after
  editing source ships stale (or missing) content.
- Neither the reference implementations nor `description.md` should mention ArrayV anywhere —
  this content ships in the app and is written as this project's own original reference material,
  not a derivative credit/attribution of the source it was ported from.
- `test`/`lint`/`format` need real toolchains installed (clang, javac/java, kotlinc, python3, ruby,
  swiftc, node, go, dotnet) — run `uv run manage.py setup` once per machine to get everything
  Homebrew can install.
- `pack` operates on the whole corpus (all algorithm folders), not just the one you're adding —
  running it after adding one algorithm regenerates `AlgorithmDetails.algz` for everyone, which is
  expected and fine to commit as one diff.
- Writing all 10 languages for several algorithms in parallel across background agents works well
  as long as each agent owns exactly one algorithm's folder — no file conflicts even without
  worktree isolation, since the shared files (registration call sites, `PORT_INVENTORY.md`) are
  edited by the orchestrating turn, never by the per-algorithm agents.

## 5. Growth-model calibration

```sh
cd Tools/GrowthModelCalibration
uv run run_calibration.py            # starts the bridge server, runs GrowthModelCalibrationTests
                                      # via xcodebuild, writes output/sort-growth-models.json
uv run apply_growth_models.py --only <algorithm-id>[,<algorithm-id>...]
                                      # bakes the fitted OperationGrowthModel(...) into each
                                      # algorithm's Swift source file directly
```

- No `--algorithm` filter needed on `run_calibration.py` — `GrowthModelCalibrationTests` resumes
  from the existing JSON report and automatically limits itself to whatever new `AlgorithmID`s
  were added to `AllBuiltInAlgorithms.sorts` in step 2. This is also why step 2 has to happen
  before this step.
- **Known bug, recurs every time**: `apply_growth_models.py`'s `insert_growth_model` inserts a new
  `growthModel: OperationGrowthModel(...)` block unconditionally after the `sizeRange:` line — it
  does not detect or remove a pre-existing one. If the source file already had a placeholder
  `growthModel:` (e.g. copied from a sibling algorithm in step 1), the result is two `growthModel:`
  labeled arguments to the same initializer call, which fails to compile. **Always** grep the
  freshly-touched `.swift` files for a duplicate `growthModel: OperationGrowthModel(` right after
  running `apply_growth_models.py` and delete the stale one by hand.
- `sizeRange` picked in step 1 was a placeholder — after calibration reports a real safe-max-size
  per operation cap, tighten `sizeRange`'s upper bound to match (the app caps most algorithms at
  256; an algorithm ArrayV itself flags as impractical past a much smaller size, like `HanoiSort`,
  should get a real measured ceiling instead of the blanket default).
- Rebuild/retest after this step — `apply_growth_models.py` edits Swift source directly, so it's a
  normal compile-and-verify step, not just data generation.

## 6. Close out `PORT_INVENTORY.md`

Delete the shipped algorithm's line from its category's "Not Started" list (delete-on-ship, not
archive-with-a-note — see the file's own recent history for the convention). If it was the last
member of an effort tier or cluster, remove the now-empty tier heading too.

## 7. Final verification

- Full build + test suite for the affected targets (`BuiltInAlgorithms`, the app target).
- Re-run `manage.py test`/`lint`/`format` are already clean from step 4 — no separate re-check
  needed unless step 5 or 6 touched the content bundle (it shouldn't).
- `git status`/`git diff --stat` sanity check before committing: expect changes in the new source
  file, the 3 registration call sites, `AlgorithmDetails.algz` + the new `<algorithm-id>/` content
  folder, `Tools/GrowthModelCalibration/output/*.json`, and `PORT_INVENTORY.md`.
