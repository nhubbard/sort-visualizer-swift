"""Offline sound-coverage audit for exported `.tape` archives.

Dev-tool only — never built into or shipped with the app. Parses the same `.tape` archive format
`Modules/SortEngineKit/Sources/{Tape+Archive,TapeArchiveEnvelope,TapeArchivePayload}.swift` produce
(a "STAP"-magic envelope wrapping a zstd-compressed, SHA-256-checked "TAPE"-magic payload) and
reports, per algorithm, how much of its recorded tape is silence (no `.compare`/`.swap`/
`.setValue`) versus audible.

Tapes are produced by `SortSession.exportTapeForAuditIfRequested` (`Modules/SortFeature/Sources/
SortSession.swift`), which only ever runs when the app process has `SORT_TAPE_EXPORT_DIR` set —
see this directory's README.md for how to populate a directory of tapes, then run:

    uv run audit_sound_coverage.py /tmp/sort-tape-audit
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from dataclasses import dataclass
from pathlib import Path

import zstandard

STAP_MAGIC = b"STAP\r\n\x1a\n"
TAPE_MAGIC = b"TAPE"
FIXED_HEADER_SIZE = 80
DEFAULT_SPEED = 30.0  # ops/sec, matching AppSettings.playbackSpeed's/ReplayEngine.speed's default.

# Tag byte -> number of trailing Int32 fields, matching `TapeArchivePayload.swift`'s `encode`/
# `decode` exactly (`SortOperation`'s own declaration order, tags 0 through 11).
OPERATION_FIELD_COUNTS = {
    0: 2,  # swap(Int, Int)
    1: 2,  # setValue(Int, Int)
    2: 2,  # mark(marker:, index:)
    3: 1,  # unmark(marker:)
    4: 0,  # unmarkAll
    5: 2,  # unmarkIndex(marker:, index:)
    6: 2,  # compare(Int, Int)
    7: 1,  # markSorted(Int)
    8: 2,  # auxCreate(handle:, length:)
    9: 3,  # auxWrite(handle:, index:, value:)
    10: 1,  # auxDelete(handle:)
    11: 0,  # reversal
}
# .compare / .swap / .setValue only — mirrors `SortOperation.isAudible`
# (Modules/SortEngineKit/Sources/SortOperation.swift). Keep in sync by hand: Python can't import
# that Swift enum, so this is a hand-maintained mirror, not a derived value.
AUDIBLE_TAGS = {0, 1, 6}


class TapeFormatError(Exception):
    """The archive doesn't match the format `Tape+Archive.swift` produces."""


class ByteReader:
    """Cursor-based little-endian reader — the same shape as `TapeArchiveByteReader` (Swift)."""

    def __init__(self, data: bytes, offset: int = 0) -> None:
        self.data = data
        self.offset = offset

    def read(self, count: int) -> bytes:
        if count < 0 or self.offset + count > len(self.data):
            raise TapeFormatError(f"truncated read of {count} bytes at offset {self.offset}")
        chunk = self.data[self.offset : self.offset + count]
        self.offset += count
        return chunk

    def read_uint(self, byte_count: int) -> int:
        return int.from_bytes(self.read(byte_count), "little", signed=False)

    def read_int32(self) -> int:
        return int.from_bytes(self.read(4), "little", signed=True)

    def read_string(self) -> str:
        length = self.read_uint(2)
        return self.read(length).decode("utf-8")

    def skip(self, count: int) -> None:
        self.read(count)


@dataclass
class TapeReport:
    algorithm_id: str
    total_operations: int
    audible_operations: int
    longest_gap_operations: int

    @property
    def audible_fraction(self) -> float:
        return self.audible_operations / self.total_operations if self.total_operations else 0.0

    def longest_gap_seconds(self, speed: float) -> float:
        return self.longest_gap_operations / speed


def parse_envelope(data: bytes) -> bytes:
    """Verifies the "STAP" envelope, zstd-decompresses the frame, and checks its SHA-256 —
    mirrors `TapeArchiveEnvelope.parse`/`Tape.init(archivedData:)` exactly. Returns the decompressed
    "TAPE" payload."""
    reader = ByteReader(data)
    magic = reader.read(8)
    if magic != STAP_MAGIC:
        raise TapeFormatError(f"bad envelope magic {magic!r}")

    major = reader.read_uint(2)
    reader.skip(2)  # minor, ignored
    header_length = reader.read_uint(4)
    flags = reader.read_uint(4)
    codec = reader.read_uint(2)
    reader.skip(2)  # reserved, ignored

    if major != 1:
        raise TapeFormatError(f"unsupported version {major}")
    if codec != 1:
        raise TapeFormatError(f"unsupported codec {codec}")
    if flags != 0:
        raise TapeFormatError(f"unexpected flags {flags}")
    if header_length < FIXED_HEADER_SIZE or header_length > len(data):
        raise TapeFormatError("invalid header length")

    frame_offset = reader.read_uint(8)
    frame_length = reader.read_uint(8)
    decompressed_length = reader.read_uint(8)
    sha256 = reader.read(32)

    if frame_offset > len(data) or frame_length > len(data) - frame_offset:
        raise TapeFormatError("invalid frame range")

    frame = data[frame_offset : frame_offset + frame_length]
    decompressor = zstandard.ZstdDecompressor()
    payload = decompressor.decompress(frame, max_output_size=decompressed_length)
    if len(payload) != decompressed_length:
        raise TapeFormatError("decompressed length mismatch")
    if hashlib.sha256(payload).digest() != sha256:
        raise TapeFormatError("sha256 mismatch")
    return payload


def parse_payload(payload: bytes, *, include_shuffle: bool) -> TapeReport:
    """Parses the "TAPE" payload's header fields (skipping over ones this tool doesn't need) and
    every operation's tag byte, computing the sound-coverage report in one pass — mirrors
    `TapeArchivePayload.decode` field-for-field, but classifies+gaps operations instead of building
    a `Tape`."""
    reader = ByteReader(payload)
    magic = reader.read(4)
    if magic != TAPE_MAGIC:
        raise TapeFormatError(f"bad tape magic {magic!r}")

    algorithm_id = reader.read_string()

    initial_value_count = reader.read_uint(4)
    reader.skip(initial_value_count * 4)

    reader.skip(8)  # visualSeed
    reader.skip(4 * 5)  # compareCount, swapCount, mainWriteCount, auxWriteCount, reversalCount
    reader.skip(8 * 2)  # recordingDuration, recordedAt

    has_shuffle_id = reader.read_uint(1)
    if has_shuffle_id == 1:
        reader.read_string()
    elif has_shuffle_id != 0:
        raise TapeFormatError("invalid hasShuffleID flag")

    sort_start_index = reader.read_int32()

    has_unique_value_count = reader.read_uint(1)
    if has_unique_value_count == 1:
        reader.skip(4)
    elif has_unique_value_count != 0:
        raise TapeFormatError("invalid hasUniqueValueCount flag")

    operation_count = reader.read_uint(4)

    audible_indices: list[int] = []
    for index in range(operation_count):
        tag = reader.read_uint(1)
        field_count = OPERATION_FIELD_COUNTS.get(tag)
        if field_count is None:
            raise TapeFormatError(f"unknown operation tag {tag}")
        reader.skip(field_count * 4)
        if tag in AUDIBLE_TAGS:
            audible_indices.append(index)

    if reader.offset != len(payload):
        raise TapeFormatError("trailing bytes after operation list")

    if include_shuffle:
        total_operations = operation_count
    else:
        total_operations = operation_count - sort_start_index
        audible_indices = [i - sort_start_index for i in audible_indices if i >= sort_start_index]

    return build_report(algorithm_id, total_operations, audible_indices)


def build_report(algorithm_id: str, total_operations: int, audible_indices: list[int]) -> TapeReport:
    """The longest silent streak is the max of: the leading gap before the first audible op, the
    trailing gap after the last one, and every interior gap between consecutive audible ops."""
    if not audible_indices:
        return TapeReport(algorithm_id, total_operations, 0, total_operations)

    longest_gap = audible_indices[0]
    longest_gap = max(longest_gap, total_operations - 1 - audible_indices[-1])
    for a, b in zip(audible_indices, audible_indices[1:]):
        longest_gap = max(longest_gap, b - a - 1)

    return TapeReport(algorithm_id, total_operations, len(audible_indices), longest_gap)


def audit_file(path: Path, *, include_shuffle: bool) -> TapeReport:
    payload = parse_envelope(path.read_bytes())
    return parse_payload(payload, include_shuffle=include_shuffle)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "directory", nargs="?", default="/tmp/sort-tape-audit",
        help="directory of .tape files to audit (default: /tmp/sort-tape-audit)")
    parser.add_argument(
        "--speed", type=float, default=DEFAULT_SPEED,
        help=f"ops/sec used to convert gaps to seconds (default: {DEFAULT_SPEED})")
    parser.add_argument(
        "--include-shuffle", action="store_true",
        help="audit the full shuffle+sort tape instead of just the sort portion (default: sort only)")
    args = parser.parse_args()

    directory = Path(args.directory)
    tape_paths = sorted(directory.glob("*.tape"))
    if not tape_paths:
        print(f"no .tape files found in {directory}", file=sys.stderr)
        return 1

    reports: list[TapeReport] = []
    for path in tape_paths:
        try:
            reports.append(audit_file(path, include_shuffle=args.include_shuffle))
        except TapeFormatError as error:
            print(f"SKIPPED {path.name}: {error}", file=sys.stderr)

    reports.sort(key=lambda r: r.longest_gap_seconds(args.speed), reverse=True)

    print(
        f"{'algorithm':<30} {'total ops':>10} {'audible %':>10} "
        f"{'longest gap (ops)':>18} {'longest gap (s)':>16}")
    for report in reports:
        print(
            f"{report.algorithm_id:<30} {report.total_operations:>10} "
            f"{report.audible_fraction * 100:>9.1f}% "
            f"{report.longest_gap_operations:>18} "
            f"{report.longest_gap_seconds(args.speed):>16.2f}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
