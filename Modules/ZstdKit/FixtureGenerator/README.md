# ZstdKit fixture generator

Generates `Modules/ZstdKit/Tests/Fixtures/*.zst` + `*.expected` pairs, self-verified against the
reference `zstandard` package before being written — see `generate.py`'s module docstring for the
encoder-derived vs. hand-crafted split. Not run by the build; a one-time authoring tool, kept
outside `Tests/` so its `.venv`/`uv.lock` never land in Tuist's test-target source glob.

```sh
cd Modules/ZstdKit/FixtureGenerator
uv run generate.py
```

## Golden/decodecorpus fixtures (`golden_*`, `decodecorpus_*`)

A second, separate set of fixtures cross-checks `ZstdKit` against the real Zstandard project's own
test suite (`~/zstd/tests/`), not just this project's own hand-picked/self-generated ones — see
`COMPRESSION_DESIGN.md`'s "Verification" section and `Tests/GoldenCorpusTests.swift`. Authored the
same way as `generate.py` above (offline, oracle-verified once, then committed) but using the real
`zstd`/`unzstd` CLI and a real `~/zstd` checkout directly rather than the Python `zstandard`
package — `swift test`/CI never shells out or needs zstd installed. To regenerate:

- **`golden_decompression_*`** (4 files, from `~/zstd/tests/golden-decompression/`): copy each
  `.zst` in verbatim; `.expected` is that same file decoded with real `unzstd -d`.
- **`golden_decompression_error_*`** (3 files, from `~/zstd/tests/golden-decompression-errors/`):
  copy each `.zst` in verbatim, no `.expected` — these must always throw.
- **`golden_compression_*`** (4 files, from `~/zstd/tests/golden-compression/`, treated as
  arbitrary binary input — matches upstream's own `zstd -c -r golden-compression | zstd -t` usage):
  compress each with `ZstdKit`'s own `Zstd.compress`, oracle-verify the result decodes correctly
  via real `unzstd`, then commit the resulting `.zst` (pins the encoder's deterministic output) and
  the original bytes as `.expected`.
- **`decodecorpus_*`** (800 files): upstream's own synthetic-valid-frame generator. Build it once
  (`cd ~/zstd && make -C lib libzstd.a && make -C tests decodecorpus`), then run it across a few
  configurations for coverage breadth, verifying every resulting frame against real `unzstd` before
  committing:
  ```sh
  ./decodecorpus -s7  -n200 --max-content-size-log=14                         -o<dir>/orig -p<dir>/comp
  ./decodecorpus -s13 -n200 --max-content-size-log=17                         -o<dir>/orig -p<dir>/comp
  ./decodecorpus -s21 -n100 --max-content-size-log=10 --block-type=0          -o<dir>/orig -p<dir>/comp
  ./decodecorpus -s22 -n100 --max-content-size-log=10 --block-type=1 --content-size -o<dir>/orig -p<dir>/comp
  ./decodecorpus -s23 -n100 --max-content-size-log=12 --block-type=2          -o<dir>/orig -p<dir>/comp
  ./decodecorpus -s31 -n100 --max-content-size-log=12 --content-size          -o<dir>/orig -p<dir>/comp
  ```
  Concatenate each batch's `orig`/`comp` pairs into `decodecorpus_NNN.expected`/`.zst` with a single
  continuous zero-padded index across all batches.

### Archiving step (required — these don't stay as loose files)

1,619 individual `golden_*`/`decodecorpus_*` files is too many to keep in the repo, so once
generated (and, for `decodecorpus_*`, oracle-verified) they get bundled into two compressed
archives and the loose files are deleted:

```sh
cd Modules/ZstdKit/FixtureGenerator
swift build_fixture_archives.swift
rm Modules/ZstdKit/Tests/Fixtures/golden_*.{zst,expected}
rm Modules/ZstdKit/Tests/Fixtures/decodecorpus_*.{zst,expected}
```

`build_fixture_archives.swift` globs those prefixes out of `Tests/Fixtures/`, bundles each group
into `golden.fixtures.zbin`/`decodecorpus.fixtures.zbin`, and self-verifies by decompressing its
own output and comparing every entry back against the original bytes before printing success —
only delete the loose files after that verification passes. Deliberately uses Apple's
`Compression` framework (`NSData.compressed(using: .zlib)`), not `ZstdKit`, for both this script
and the runtime extraction side (`Tests/FixtureArchive.swift`) — depending on `ZstdKit` to unpack
its own test fixtures would be circular. `swift test`/CI never installs or shells out to real zstd
for this step; `FixtureArchive` decompresses the committed `.zbin` files into a temp directory at
test time and deletes it on process exit.

To regenerate either archive from scratch: rerun the relevant generation step above (both are
fully deterministic given the documented seeds/commands), then rerun this archiving step.
