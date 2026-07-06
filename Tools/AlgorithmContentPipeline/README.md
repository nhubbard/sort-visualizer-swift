# Algorithm Content Pipeline

Generates the syntax-highlighted code samples consumed by `App/Resources/AlgorithmDetails/`
(via `Modules/DesignSystemKit/Sources/CodeAttributes.swift`'s Pygments-token-based markdown).
Preserved from `Legacy/Shared/Resources/` when the rest of `Legacy/` was removed (Phase 11) —
this is the only part of `Legacy/` still in active use.

## Layout

- `<algorithm>.bundle/` — one folder per algorithm. Each contains raw source
  (`<algorithm>.<ext>` for `ext` in `c cpp cs go java js kt py rb swift`), the algorithm's
  `description.md`, and (after running `highlight.py`) a generated `<algorithm>.<ext>.md` per
  source file.
- `template/` — master template used by `scaffold.sh` to start a new bundle.
- `highlight.py` — runs Pygments over each bundle's raw source, writing `<file>.md` in the
  `^[text](code: 'Token.X')` syntax `CodeAttributes` parses. Add new algorithm names to its
  `algorithms` list before running.
- `test.py` — compiles/runs each bundle's raw source per language and checks output against an
  expected sorted result, to verify correctness before highlighting. `python3 test.py [name]`
  (all bundles if no name given). Needs the actual toolchains installed (clang, javac/java,
  kotlinc, python3, ruby, swiftc, node, go, csc/mono — whichever languages you're checking).
- `scaffold.sh <name>` — creates `<name>.bundle/` from `template/`.

## Usage

```sh
cd Tools/AlgorithmContentPipeline
python3 -m venv .venv && source .venv/bin/activate
pip install pygments coloredlogs   # coloredlogs only needed for test.py
python3 highlight.py
```

After generating, copy `description.md` and the language `.md` files you want into
`App/Resources/AlgorithmDetails/<algorithm-id>/`, renamed to match `CodeLanguage.all`'s ids
(`py.md`, `js.md`, `go.md`, `java.md`, `c.md`, `cpp.md`, `cs.md`, `rb.md`, `kt.md`, `swift.md`) —
`AlgorithmDetailContent` reads by language id, not by the pipeline's `<algorithm>.<ext>.md` naming.
