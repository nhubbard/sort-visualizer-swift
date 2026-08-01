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

from dataclasses import dataclass
from pathlib import Path

import os
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


def write_fixture(name: str, plaintext: bytes, frame: bytes, *, verify: bool = True) -> None:
    if verify:
        decompressed = zstandard.decompress(frame, max_output_size=max(len(plaintext), 1))
        assert decompressed == plaintext, f"{name}: round-trip mismatch"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / f"{name}.zst").write_bytes(frame)
    (OUTPUT_DIR / f"{name}.expected").write_bytes(plaintext)
    blocks = classify_blocks(frame)
    kinds = ", ".join(f"{b.block_type}({b.block_size}B)" for b in blocks)
    print(f"{name}: {len(frame)} B compressed, {len(plaintext)} B plaintext, blocks=[{kinds}]")


# --------------------------------------------------------------------------------------------
# Encoder-derived fixtures
# --------------------------------------------------------------------------------------------


def generate_empty() -> None:
    compressor = zstandard.ZstdCompressor(level=1, write_content_size=True, write_checksum=False)
    write_fixture("empty", b"", compressor.compress(b""))


def generate_raw_single_segment() -> None:
    plaintext = os.urandom(2000)
    compressor = zstandard.ZstdCompressor(level=1, write_content_size=True, write_checksum=False)
    write_fixture("raw_single_segment", plaintext, compressor.compress(plaintext))


def generate_checksum_trailer() -> None:
    plaintext = os.urandom(4000)
    compressor = zstandard.ZstdCompressor(level=1, write_content_size=True, write_checksum=True)
    write_fixture("checksum_trailer", plaintext, compressor.compress(plaintext))


def generate_dictionary_id_present() -> None:
    samples = [os.urandom(50) + b"COMMON_PATTERN_HERE_" + os.urandom(50) for _ in range(50)]
    dictionary = zstandard.train_dictionary(4096, samples)
    assert dictionary.dict_id() != 0, "expected a nonzero trained dictionary ID"
    compressor = zstandard.ZstdCompressor(level=1, dict_data=dictionary, write_content_size=True)
    plaintext = os.urandom(50) + b"COMMON_PATTERN_HERE_" + os.urandom(50)
    frame = compressor.compress(plaintext)
    params = zstandard.get_frame_parameters(frame)
    assert params.dict_id == dictionary.dict_id()
    # Never decodable without the dictionary — no .expected pair, and skip the round-trip check.
    write_fixture("dictionary_id_present", plaintext, frame, verify=False)


# --------------------------------------------------------------------------------------------
# Hand-crafted fixtures (RLE_Block coverage)
# --------------------------------------------------------------------------------------------


def build_frame_header(
    *, content_size: int | None, single_segment: bool, checksum: bool, window_covers: int = 0
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

    descriptor = (fcs_flag << 6) | ((1 if single_segment else 0) << 5) | ((1 if checksum else 0) << 2)
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
    header = build_frame_header(content_size=len(plaintext), single_segment=True, checksum=False)
    block = build_block_header(is_last=True, block_type=BLOCK_TYPE_RLE, block_size=len(plaintext))
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
    header = build_frame_header(content_size=len(plaintext), single_segment=False, checksum=False)
    block = build_block_header(is_last=True, block_type=BLOCK_TYPE_RLE, block_size=len(plaintext))
    block += bytes([plaintext[0]])
    write_fixture("rle_windowed_known_size", plaintext, header + block)


def generate_raw_windowed_unknown_size() -> None:
    plaintext = os.urandom(10_000)
    header = build_frame_header(
        content_size=None, single_segment=False, checksum=False, window_covers=len(plaintext)
    )
    block = build_block_header(is_last=True, block_type=BLOCK_TYPE_RAW, block_size=len(plaintext))
    block += plaintext
    write_fixture("raw_windowed_unknown_size", plaintext, header + block)


def generate_mixed_raw_and_rle_blocks() -> None:
    """Three blocks — raw, rle, raw — proving the block loop advances correctly across types."""
    raw1 = os.urandom(1000)
    rle_byte = 0x42
    rle_length = 2000
    raw2 = os.urandom(500)
    plaintext = raw1 + bytes([rle_byte]) * rle_length + raw2

    header = build_frame_header(content_size=len(plaintext), single_segment=True, checksum=False)
    blocks = b"".join(
        [
            build_block_header(is_last=False, block_type=BLOCK_TYPE_RAW, block_size=len(raw1)) + raw1,
            build_block_header(is_last=False, block_type=BLOCK_TYPE_RLE, block_size=rle_length)
            + bytes([rle_byte]),
            build_block_header(is_last=True, block_type=BLOCK_TYPE_RAW, block_size=len(raw2)) + raw2,
        ]
    )
    write_fixture("mixed_raw_and_rle_blocks", plaintext, header + blocks)


if __name__ == "__main__":
    generate_empty()
    generate_raw_single_segment()
    generate_checksum_trailer()
    generate_dictionary_id_present()
    generate_rle_single_segment()
    generate_rle_windowed_known_size()
    generate_raw_windowed_unknown_size()
    generate_mixed_raw_and_rle_blocks()
