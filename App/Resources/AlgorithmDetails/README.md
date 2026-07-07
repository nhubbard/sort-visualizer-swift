# Algorithm Content Pipeline

Generates the syntax-highlighted code samples consumed by this same directory's plain
`<algorithm-id>/` folders (via `Modules/DesignSystemKit/Sources/CodeAttributes.swift`'s
Pygments-token-based markdown). Originally `Tools/AlgorithmContentPipeline/`, preserved from
`Legacy/Shared/Resources/` when the rest of `Legacy/` was removed (Phase 11) — this was the only
part of `Legacy/` still in active use, and was later folded into `App/Resources/AlgorithmDetails/`
so the pipeline and its shipped output live in one place instead of two.

## Layout

This directory holds two kinds of content side by side — `Project.swift`'s `copyFiles` phase
(`Module.algorithmDetailCopyFiles`) discovers and ships only the second kind, by one rule: any
subdirectory here that does **not** end in `.bundle` is treated as shipped output.

- `<algorithm>.bundle/` — one authoring folder per algorithm, **not shipped**. Each contains raw
  source (`<algorithm>.<ext>` for `ext` in `c cpp cs go java js kt py rb swift`), the algorithm's
  `description.md`, `complexity.json`, and (after running `highlight.py`) a generated
  `<algorithm>.<ext>.md` per source file.
- `template.bundle/` — master template used by `scaffold.sh` to start a new bundle, **not
  shipped** (named `.bundle` for the same reason every other authoring folder is: so the
  "shipped vs. not" rule above doesn't need a special case for it).
- `highlight.py` — runs Pygments over each bundle's raw source, writing `<file>.md` in the
  `^[text](code: 'Token.X')` syntax `CodeAttributes` parses. Add new algorithm names to its
  `algorithms` list before running. **Not shipped** (a loose `.py` file, not a directory, so it's
  never a candidate either way).
- `test.py` — compiles/runs each bundle's raw source per language and checks output against an
  expected sorted result, to verify correctness before highlighting. `python3 test.py [name]`
  (all bundles if no name given). Needs the actual toolchains installed (clang, javac/java,
  kotlinc, python3, ruby, swiftc, node, go, csc/mono — whichever languages you're checking).
  **Not shipped.**
- `scaffold.sh <name>` — creates `<name>.bundle/` from `template.bundle/`. **Not shipped.**
- `<algorithm-id>/` — one **shipped** folder per algorithm with finished content: `description.md`
  + per-language `<lang>.md`, renamed to match `CodeLanguage.all`'s ids (`py.md`, `js.md`, `go.md`,
  `java.md`, `c.md`, `cpp.md`, `cs.md`, `rb.md`, `kt.md`, `swift.md`) — `AlgorithmDetailContent`
  reads by language id, not by the pipeline's `<algorithm>.<ext>.md` naming.

## Usage

```sh
cd App/Resources/AlgorithmDetails
python3 -m venv .venv && source .venv/bin/activate
pip install pygments coloredlogs   # coloredlogs only needed for test.py
python3 highlight.py
```

After generating, copy `description.md` and the language `.md` files you want into this
directory's `<algorithm-id>/` (not `<algorithm-id>.bundle/` — that's the source, never read by the
app), renamed as described above. This step is still manual; nothing currently regenerates the
shipped `<algorithm-id>/` folders from a bundle automatically.

## Known naming/coverage gaps

These predate the pipeline moving into this directory and are unrelated to it — flagged here only
because the mismatched folders now sit as literal siblings, where they're easy to mistake for a
1:1 correspondence:

- `heapsort.bundle/` authors content for what ships as `maxheapsort/`.
- `bitonicsort.bundle/` authors content for what ships as `bitonicsortiterative/`.
- `radixsort.bundle/`, `shakersort.bundle/` have no shipped `<algorithm-id>/` counterpart at all —
  dead leftovers from before `cocktailshakersort`/the radix sorts were ported under their current
  ids; `oddevensort.bundle/` and `stoogesort.bundle/` used to be in this same boat but now ship as
  `oddevensort/`/`stoogesort/` (the native port batch that added `OddEvenSort`/`StoogeSort`).
- `lsdradixsort/` ships without any authoring bundle behind it.
