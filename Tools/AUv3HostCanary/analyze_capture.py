#!/usr/bin/env python3
"""Check two Logic Bus 1 recordings of the AUv3 with Gain 1 and Gain 0.

The recordings must be made while the standalone app runs a sort. Logic's
instrument output goes to Bus 1, which is the input of a record-enabled audio
track. The script decodes the host's audio files to float PCM with ffmpeg.
"""

import argparse
import array
import math
import subprocess


def measure(path):
    process = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-acodec", "pcm_f32le", "-"],
        check=True,
        stdout=subprocess.PIPE,
    )
    samples = array.array("f")
    samples.frombytes(process.stdout)
    if not samples:
        raise ValueError(f"Empty audio capture: {path}")
    peak = max(abs(value) for value in samples)
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    nonzero = sum(value != 0 for value in samples)
    return len(samples), peak, rms, nonzero


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("audible", help="Host recording with AU Gain 1")
    parser.add_argument("muted", help="Host recording with AU Gain 0")
    args = parser.parse_args()

    for label, path in (("Gain 1", args.audible), ("Gain 0", args.muted)):
        count, peak, rms, nonzero = measure(path)
        print(f"{label}: samples={count}, peak={peak:.9f}, rms={rms:.9f}, nonzero={nonzero}")
        if label == "Gain 1" and (peak < 0.01 or nonzero < 1000):
            raise AssertionError("Gain 1 host capture is not audibly populated")
        if label == "Gain 0" and nonzero != 0:
            raise AssertionError("Gain 0 host capture is not digitally silent")
    print("PASS: the host parameter changes rendered output")


if __name__ == "__main__":
    main()
