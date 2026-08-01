# ZstdKit fixture generator

Generates `Modules/ZstdKit/Tests/Fixtures/*.zst` + `*.expected` pairs, self-verified against the
reference `zstandard` package before being written — see `generate.py`'s module docstring for the
encoder-derived vs. hand-crafted split. Not run by the build; a one-time authoring tool, kept
outside `Tests/` so its `.venv`/`uv.lock` never land in Tuist's test-target source glob.

```sh
cd Modules/ZstdKit/FixtureGenerator
uv run generate.py
```
