#!/usr/bin/env python3
"""Generates ZstdKit's Milestone-A test fixtures: `<name>.zst` (compressed) + `<name>.expected`
(raw plaintext) pairs, self-verified against the reference `zstandard` package before being
written. Not run by the build — a one-time authoring tool, like `manage.py` is for
`AlgorithmDetails/`. Re-run with `uv run generate.py` whenever fixture coverage needs to change.

Two sources of fixtures:
- Encoder-derived: real `zstandard.ZstdCompressor` output. Covers `Raw_Block`, frame headers, the
  content checksum trailer, and dictionary-ID rejection — cases the reference encoder reliably
  produces from the right kind of input.
- Hand-crafted: `RLE_Block` is one of the two "trivial" block types the decoder milestone targets
  directly, but the reference encoder never emits a bare `RLE_Block` as a frame's first block (it
  always wraps at least the first ~128 KB in a `Compressed_Block`, even for fully-constant input —
  confirmed empirically, not an assumption). So RLE coverage is built byte-for-byte here instead,
  each one verified by decompressing it with the *reference* `zstandard` package before being
  trusted — this proves the hand-built bytes are spec-compliant, not just "whatever our own
  decoder happens to accept".
"""

from __future__ import annotations

import random
from dataclasses import dataclass
from pathlib import Path

import zstandard

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "Tests" / "Fixtures"
MAGIC = bytes.fromhex("28b52ffd")


@dataclass(frozen=True)
class BlockSummary:
    block_type: str
    block_size: int
    is_last: bool


def classify_blocks(frame: bytes) -> list[BlockSummary]:
    """A minimal reference block-header walker, used only to confirm each fixture actually
    exercises the block type its name promises — not a stand-in for Swift-side correctness.
    """
    params = zstandard.get_frame_parameters(frame)
    descriptor = frame[4]
    pos = 5
    single_segment = bool((descriptor >> 5) & 0x1)
    if not single_segment:
        pos += 1  # window descriptor
    dict_id_flag = descriptor & 0x3
    pos += [0, 1, 2, 4][dict_id_flag]
    fcs_flag = (descriptor >> 6) & 0x3
    fcs_size = {0: 1 if single_segment else 0, 1: 2, 2: 4, 3: 8}[fcs_flag]
    pos += fcs_size

    summaries = []
    while True:
        raw = int.from_bytes(frame[pos : pos + 3], "little")
        pos += 3
        is_last = bool(raw & 0x1)
        block_type_id = (raw >> 1) & 0x3
        block_size = (raw >> 3) & 0x1FFFFF
        block_type = ["raw", "rle", "compressed", "reserved"][block_type_id]
        summaries.append(BlockSummary(block_type, block_size, is_last))
        pos += 1 if block_type == "rle" else block_size
        if is_last:
            break
    if params.has_checksum:
        pos += 4
    assert pos == len(frame), f"block walk ended at {pos}, frame is {len(frame)} bytes"
    return summaries


def write_fixture(
    name: str, plaintext: bytes, frame: bytes, *, verify: bool = True
) -> None:
    if verify:
        decompressed = zstandard.decompress(
            frame, max_output_size=max(len(plaintext), 1)
        )
        assert decompressed == plaintext, f"{name}: round-trip mismatch"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / f"{name}.zst").write_bytes(frame)
    (OUTPUT_DIR / f"{name}.expected").write_bytes(plaintext)
    blocks = classify_blocks(frame)
    kinds = ", ".join(f"{b.block_type}({b.block_size}B)" for b in blocks)
    print(
        f"{name}: {len(frame)} B compressed, {len(plaintext)} B plaintext, blocks=[{kinds}]"
    )


# --------------------------------------------------------------------------------------------
# Encoder-derived fixtures
# --------------------------------------------------------------------------------------------


def generate_empty() -> None:
    compressor = zstandard.ZstdCompressor(
        level=1, write_content_size=True, write_checksum=False
    )
    write_fixture("empty", b"", compressor.compress(b""))


def generate_raw_single_segment() -> None:
    plaintext = random.Random(1).randbytes(2000)
    compressor = zstandard.ZstdCompressor(
        level=1, write_content_size=True, write_checksum=False
    )
    write_fixture("raw_single_segment", plaintext, compressor.compress(plaintext))


def generate_checksum_trailer() -> None:
    plaintext = random.Random(2).randbytes(4000)
    compressor = zstandard.ZstdCompressor(
        level=1, write_content_size=True, write_checksum=True
    )
    write_fixture("checksum_trailer", plaintext, compressor.compress(plaintext))


def generate_dictionary_id_present() -> None:
    rng = random.Random(4)
    samples = [
        rng.randbytes(50) + b"COMMON_PATTERN_HERE_" + rng.randbytes(50)
        for _ in range(50)
    ]
    dictionary = zstandard.train_dictionary(4096, samples)
    assert dictionary.dict_id() != 0, "expected a nonzero trained dictionary ID"
    compressor = zstandard.ZstdCompressor(
        level=1, dict_data=dictionary, write_content_size=True
    )
    plaintext = rng.randbytes(50) + b"COMMON_PATTERN_HERE_" + rng.randbytes(50)
    frame = compressor.compress(plaintext)
    params = zstandard.get_frame_parameters(frame)
    assert params.dict_id == dictionary.dict_id()
    # Never decodable without the dictionary — no .expected pair, and skip the round-trip check.
    write_fixture("dictionary_id_present", plaintext, frame, verify=False)


# --------------------------------------------------------------------------------------------
# Hand-crafted fixtures (RLE_Block coverage)
# --------------------------------------------------------------------------------------------


def build_frame_header(
    *,
    content_size: int | None,
    single_segment: bool,
    checksum: bool,
    window_covers: int = 0,
) -> bytes:
    """`window_covers` sizes the window descriptor when `content_size` is `None` — the window
    must still be large enough to hold whatever content the caller actually plans to emit, even
    though that size isn't being declared in the header.
    """
    if content_size is None:
        fcs_flag, fcs_field_size = 0, 0
    elif single_segment:
        if content_size <= 255:
            fcs_flag, fcs_field_size = 0, 1
        elif content_size <= 65535 + 256:
            fcs_flag, fcs_field_size = 1, 2
        elif content_size <= 0xFFFF_FFFF:
            fcs_flag, fcs_field_size = 2, 4
        else:
            fcs_flag, fcs_field_size = 3, 8
    elif content_size <= 65535 + 256 and content_size >= 256:
        fcs_flag, fcs_field_size = 1, 2
    elif content_size <= 0xFFFF_FFFF:
        fcs_flag, fcs_field_size = 2, 4
    else:
        fcs_flag, fcs_field_size = 3, 8

    descriptor = (
        (fcs_flag << 6)
        | ((1 if single_segment else 0) << 5)
        | ((1 if checksum else 0) << 2)
    )
    header = bytearray(MAGIC)
    header.append(descriptor)
    if not single_segment:
        required = content_size if content_size is not None else window_covers
        window_log = 10
        while (1 << window_log) < max(required, 1):
            window_log += 1
        header.append((window_log - 10) << 3)  # mantissa 0
    if fcs_field_size > 0:
        value = content_size - 256 if fcs_field_size == 2 else content_size
        header += value.to_bytes(fcs_field_size, "little")
    return bytes(header)


def build_block_header(*, is_last: bool, block_type: int, block_size: int) -> bytes:
    raw = (1 if is_last else 0) | (block_type << 1) | (block_size << 3)
    return raw.to_bytes(3, "little")


BLOCK_TYPE_RAW, BLOCK_TYPE_RLE = 0, 1


def generate_rle_single_segment() -> None:
    plaintext = b"A" * 10_000
    header = build_frame_header(
        content_size=len(plaintext), single_segment=True, checksum=False
    )
    block = build_block_header(
        is_last=True, block_type=BLOCK_TYPE_RLE, block_size=len(plaintext)
    )
    block += bytes([plaintext[0]])
    write_fixture("rle_single_segment", plaintext, header + block)


def generate_rle_windowed_known_size() -> None:
    """Non-single-segment (window descriptor present) framing, paired with RLE — separate from
    the unknown-size case below, since combining RLE with an *unknown* declared size trips a
    reference-`zstandard` streaming-decompressor quirk unrelated to frame-format correctness
    (confirmed empirically: RLE+known-windowed-size and Raw+unknown-size each independently
    round-trip cleanly through the reference decoder; it's specifically the combination of RLE
    and unknown size that reference `zstandard` rejects — not something our decoder needs to
    reproduce).
    """
    plaintext = b"Q" * 500_000
    header = build_frame_header(
        content_size=len(plaintext), single_segment=False, checksum=False
    )
    block = build_block_header(
        is_last=True, block_type=BLOCK_TYPE_RLE, block_size=len(plaintext)
    )
    block += bytes([plaintext[0]])
    write_fixture("rle_windowed_known_size", plaintext, header + block)


def generate_raw_windowed_unknown_size() -> None:
    plaintext = random.Random(5).randbytes(10_000)
    header = build_frame_header(
        content_size=None,
        single_segment=False,
        checksum=False,
        window_covers=len(plaintext),
    )
    block = build_block_header(
        is_last=True, block_type=BLOCK_TYPE_RAW, block_size=len(plaintext)
    )
    block += plaintext
    write_fixture("raw_windowed_unknown_size", plaintext, header + block)


def generate_mixed_raw_and_rle_blocks() -> None:
    """Three blocks — raw, rle, raw — proving the block loop advances correctly across types."""
    rng = random.Random(6)
    raw1 = rng.randbytes(1000)
    rle_byte = 0x42
    rle_length = 2000
    raw2 = rng.randbytes(500)
    plaintext = raw1 + bytes([rle_byte]) * rle_length + raw2

    header = build_frame_header(
        content_size=len(plaintext), single_segment=True, checksum=False
    )
    blocks = b"".join(
        [
            build_block_header(
                is_last=False, block_type=BLOCK_TYPE_RAW, block_size=len(raw1)
            )
            + raw1,
            build_block_header(
                is_last=False, block_type=BLOCK_TYPE_RLE, block_size=rle_length
            )
            + bytes([rle_byte]),
            build_block_header(
                is_last=True, block_type=BLOCK_TYPE_RAW, block_size=len(raw2)
            )
            + raw2,
        ]
    )
    write_fixture("mixed_raw_and_rle_blocks", plaintext, header + blocks)


# --------------------------------------------------------------------------------------------
# Milestone B: Huffman-coded literals, with zero sequences so the block's entire decompressed
# output is exactly the literals section (sequence decoding is Milestone C). Plaintexts below are
# hardcoded rather than regenerated from a `random` seed each run: they were originally found by
# scanning skewed-alphabet inputs at level 19 for ones the reference encoder happened to encode as
# `Compressed_Literals_Block` + zero sequences, and hardcoding avoids the fixture silently
# changing if Python's `random` algorithm ever shifts between versions.
# --------------------------------------------------------------------------------------------


def generate_huffman_one_stream_zero_sequences() -> None:
    plaintext = b"BDABCBCBBAAAAAAABAAAADBBABAADBBB"  # 32 B, alphabet {A,B,C,D} -- single Huffman stream
    compressor = zstandard.ZstdCompressor(
        level=19, write_content_size=True, write_checksum=False
    )
    write_fixture(
        "huffman_one_stream_zero_sequences", plaintext, compressor.compress(plaintext)
    )


def generate_huffman_four_stream_zero_sequences() -> None:
    plaintext = (
        b"BAABAABDACCACACBAADADCBDDCABABABBBCDAAACBCAACCAAADAAACAABBDABAAAAADAAADCABBDAAAA"
        b"CABBBABAABABAACAACACAAAABAABAAAABABABAAADABCAADAAABACAABAABBADAABABCBBBAAAAAAAAB"
        b"AACACAABCBBBAAABBCBDBABABAACABBCCDCBBACCAABAAACBAABABAAAABBBAAABBABAAABAAABABAAB"
        b"AAAAAAABAABACCAC"
    )  # 256 B, alphabet {A,B,C,D} -- large enough to trigger 4-stream Huffman literals
    assert len(plaintext) == 256
    compressor = zstandard.ZstdCompressor(
        level=19, write_content_size=True, write_checksum=False
    )
    write_fixture(
        "huffman_four_stream_zero_sequences", plaintext, compressor.compress(plaintext)
    )


def generate_huffman_treeless_zero_sequences() -> None:
    """Forces an explicit block boundary via the streaming API (`COMPRESSOBJ_FLUSH_BLOCK`) so the
    first block builds a real Huffman table (`Compressed_Literals_Block`) and the second reuses it
    (`Treeless_Literals_Block`) -- both empirically confirmed to still have zero sequences at this
    size, so Milestone B can exercise table persistence across blocks without Milestone C.
    """
    rng = random.Random(3)
    symbols = list(range(65, 65 + 4))  # A-D
    chunk1 = bytes(rng.choice(symbols) for _ in range(2000))
    chunk2 = bytes(rng.choice(symbols) for _ in range(2000))
    plaintext = chunk1 + chunk2

    compressor = zstandard.ZstdCompressor(
        level=19, write_content_size=True, write_checksum=False
    )
    streaming = compressor.compressobj()
    frame = streaming.compress(chunk1)
    frame += streaming.flush(zstandard.COMPRESSOBJ_FLUSH_BLOCK)
    frame += streaming.compress(chunk2)
    frame += streaming.flush(zstandard.COMPRESSOBJ_FLUSH_FINISH)

    blocks = classify_blocks(frame)
    assert len(blocks) == 2, f"expected 2 blocks, got {len(blocks)}"
    write_fixture("huffman_treeless_zero_sequences", plaintext, frame)


def _first_block_sequence_count_byte(frame: bytes) -> int:
    """Reference-parses just far enough into the first block to read Number_of_Sequences,
    independent of anything ZstdKit itself does -- used only to confirm a fixture's shape.
    """
    descriptor = frame[4]
    pos = 5
    single_segment = bool((descriptor >> 5) & 1)
    if not single_segment:
        pos += 1
    pos += [0, 1, 2, 4][descriptor & 3]
    fcs_flag = (descriptor >> 6) & 3
    pos += {0: 1 if single_segment else 0, 1: 2, 2: 4, 3: 8}[fcs_flag]
    pos += 3  # block header
    block = frame[pos:]
    b0 = block[0]
    lit_type = b0 & 3
    lhl = (b0 >> 2) & 3

    if lit_type in (
        0,
        1,
    ):  # raw/rle literals -- header_size is the section's own length,
        # and for RLE the "compressed" payload is always exactly 1 byte regardless of size.
        if lhl in (0, 2):
            header_size, payload_size = 1, (1 if lit_type == 1 else b0 >> 3)
        elif lhl == 1:
            header_size, payload_size = (
                2,
                (1 if lit_type == 1 else int.from_bytes(block[0:2], "little") >> 4),
            )
        else:
            header_size, payload_size = (
                3,
                (1 if lit_type == 1 else int.from_bytes(block[0:3], "little") >> 4),
            )
        return block[header_size + payload_size]

    lhc = int.from_bytes(block[0:4], "little")
    if lhl in (0, 1):
        csize, header_size = (lhc >> 14) & 0x3FF, 3
    elif lhl == 2:
        csize, header_size = (lhc >> 18) & 0x3FFF, 4
    else:
        lhc2 = int.from_bytes(block[1:5], "little")
        csize, header_size = lhc2 >> 2, 5
    return block[header_size + csize]


def generate_compressed_block_with_sequences() -> None:
    """Genuinely repetitive content, so the encoder finds real LZ77 matches -- unlike every other
    Milestone-B fixture, this one must NOT decode yet (`ZstdDecompressor` still throws for any
    nonzero sequence count; FSE-coded sequence decoding is Milestone C).
    """
    plaintext = b"the quick brown fox jumps over the lazy dog. " * 40
    compressor = zstandard.ZstdCompressor(
        level=19, write_content_size=True, write_checksum=False
    )
    frame = compressor.compress(plaintext)
    nb_seq_byte = _first_block_sequence_count_byte(frame)
    assert nb_seq_byte != 0, "expected a nonzero sequence count in this fixture"
    write_fixture("compressed_block_with_sequences", plaintext, frame)


# --------------------------------------------------------------------------------------------
# Milestone C/D: FSE-coded sequences + LZ77 execution. Each fixture's sequence-symbol-table modes
# (Predefined/RLE/FSE_Compressed/Repeat) were found by scanning input shapes and confirmed via
# `_sequence_table_modes` below, the same reference-parsing approach used throughout this file —
# not assumed from how the input was constructed.
# --------------------------------------------------------------------------------------------


def _literals_section_extent(block: bytes) -> tuple[int, int, int]:
    """Returns (literals_block_type, header_size, compressed_size) for the block's literals
    section — `compressed_size` doubles as the on-disk byte count for Raw (verbatim) and RLE
    (always 1) literals, matching `generate_compressed_block_with_sequences`'s helper.
    """
    b0 = block[0]
    lit_type = b0 & 3
    lhl = (b0 >> 2) & 3
    if lit_type in (0, 1):
        if lhl in (0, 2):
            header_size = 1
            regenerated_size = 1 if lit_type == 1 else (b0 >> 3)
        elif lhl == 1:
            header_size = 2
            regenerated_size = 1 if lit_type == 1 else (int.from_bytes(block[0:2], "little") >> 4)
        else:
            header_size = 3
            regenerated_size = 1 if lit_type == 1 else (int.from_bytes(block[0:3], "little") >> 4)
        return lit_type, header_size, regenerated_size

    lhc = int.from_bytes(block[0:4], "little")
    if lhl in (0, 1):
        return lit_type, 3, (lhc >> 14) & 0x3FF
    if lhl == 2:
        return lit_type, 4, (lhc >> 18) & 0x3FFF
    lhc2 = int.from_bytes(block[1:5], "little")
    return lit_type, 5, lhc2 >> 2


def _sequence_table_modes(frame: bytes, block_index: int = 0) -> str:
    """Reference-parses the requested block's Symbol_Compression_Modes -- independent
    confirmation of which mode each fixture actually exercises, same spirit as `classify_blocks`.
    """
    descriptor = frame[4]
    pos = 5
    single_segment = bool((descriptor >> 5) & 1)
    if not single_segment:
        pos += 1
    pos += [0, 1, 2, 4][descriptor & 3]
    fcs_flag = (descriptor >> 6) & 3
    pos += {0: 1 if single_segment else 0, 1: 2, 2: 4, 3: 8}[fcs_flag]

    for current_index in range(block_index + 1):
        raw = int.from_bytes(frame[pos : pos + 3], "little")
        block_size = (raw >> 3) & 0x1FFFFF
        pos += 3
        block = frame[pos : pos + block_size]
        pos += block_size

    _lit_type, header_size, csize = _literals_section_extent(block)
    seq_pos = header_size + csize
    nb = block[seq_pos]
    if nb == 0:
        return "nbSeq=0"
    seq_pos += 1
    if nb == 255:
        seq_pos += 2
    elif nb >= 128:
        seq_pos += 1
    modes_byte = block[seq_pos]
    names = ["predefined", "rle", "fse", "repeat"]
    ll, of, ml = names[(modes_byte >> 6) & 3], names[(modes_byte >> 4) & 3], names[(modes_byte >> 2) & 3]
    return f"LL={ll} OF={of} ML={ml}"


def generate_sequences_predefined_tables() -> None:
    """A single huge match collapses to exactly one sequence, cheap enough that Predefined beats
    building a custom table for all three symbol types.
    """
    plaintext = b"ab" * 5000
    compressor = zstandard.ZstdCompressor(level=19, write_content_size=True, write_checksum=False)
    frame = compressor.compress(plaintext)
    modes = _sequence_table_modes(frame)
    assert modes == "LL=predefined OF=predefined ML=predefined", modes
    write_fixture("sequences_predefined_tables", plaintext, frame)


def generate_sequences_rle_tables() -> None:
    """Many short matches all sharing the same offset and match length make Offset_Code and
    Match_Length_Code each RLE-encodable; Literal_Length_Code still varies (FSE_Compressed).
    """
    plaintext = b"".join((bytes([65 + (i % 20)]) * 4 + bytes([i % 251])) for i in range(50))
    compressor = zstandard.ZstdCompressor(level=19, write_content_size=True, write_checksum=False)
    frame = compressor.compress(plaintext)
    modes = _sequence_table_modes(frame)
    assert modes == "LL=fse OF=rle ML=rle", modes
    write_fixture("sequences_rle_tables", plaintext, frame)


def generate_sequences_repeat_and_multiblock() -> None:
    """Real production-shaped content (concatenated `AlgorithmDetails/*/*.md`, matching what
    `AlgorithmDetails.algz` actually contains): large enough to span 4 blocks, naturally mixing
    `Compressed`/`Treeless`/`Raw` literals with `FSE_Compressed` and (in the last block) `Repeat`
    sequence-symbol tables. Depends on this repo's checked-in AlgorithmDetails content rather than
    a hardcoded byte literal or RNG, since reproducing the exact block/mode split some other way
    isn't practical -- if AlgorithmDetails' content changes enough to alter this fixture's block
    layout, `generate.py`'s assertions below will fail loudly and it can be regenerated.
    """
    root = Path(__file__).resolve().parent.parent.parent.parent / "App" / "Resources" / "AlgorithmDetails"
    algorithms = ["quicksort", "mergesort", "bubblesort", "insertionsort", "maxheapsort", "selectionsort"]
    languages = ["py", "js", "go", "java", "c", "cpp"]
    plaintext = b"".join(
        (root / algorithm / f"{language}.md").read_bytes()
        for algorithm in algorithms
        for language in languages
        if (root / algorithm / f"{language}.md").exists()
    )
    assert len(plaintext) > 300_000, f"expected a large corpus, got {len(plaintext)} B"

    compressor = zstandard.ZstdCompressor(level=19, write_content_size=True, write_checksum=False)
    frame = compressor.compress(plaintext)
    blocks = classify_blocks(frame)
    assert len(blocks) >= 4, f"expected >= 4 blocks, got {len(blocks)}"
    last_block_modes = _sequence_table_modes(frame, block_index=len(blocks) - 1)
    assert "repeat" in last_block_modes, f"expected a repeat-mode table, got {last_block_modes}"
    write_fixture("sequences_repeat_and_multiblock", plaintext, frame)


if __name__ == "__main__":
    generate_empty()
    generate_raw_single_segment()
    generate_checksum_trailer()
    generate_dictionary_id_present()
    generate_rle_single_segment()
    generate_rle_windowed_known_size()
    generate_raw_windowed_unknown_size()
    generate_mixed_raw_and_rle_blocks()
    generate_huffman_one_stream_zero_sequences()
    generate_huffman_four_stream_zero_sequences()
    generate_huffman_treeless_zero_sequences()
    generate_compressed_block_with_sequences()
    generate_sequences_predefined_tables()
    generate_sequences_rle_tables()
    generate_sequences_repeat_and_multiblock()
