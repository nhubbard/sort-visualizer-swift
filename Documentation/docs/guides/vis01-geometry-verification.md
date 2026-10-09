# VIS-01 visualizer geometry verification

Date: 2026-10-04. The test corpus runs all 15 built-in visualizer geometry implementations
with 16, 256, and 1,024 values. It covers duplicate-heavy values, an all-equal range, and a
permutation. Every emitted command must have finite color and coordinates within a 400 × 300
canvas. The two dot styles also run with 1,024 values in a 4 × 3 canvas.

The existing Metal settled-image fixture checks all 15 styles at 64 elements. An expanded
Metal test renders each style at 256 and 1,024 duplicate-heavy elements, at the beginning,
middle, and end of a value-change transition. It checks that all frames are nonempty, the GPU
command succeeds, and the start and end frames differ at 256 elements. The 1,024-element
case checks visibility and GPU success; some single-element changes are fully occluded by
overlapping shapes at that density. The test prints SHA-256 frame digests and the Metal device
name for inspection. A separate Metal geometry assertion checks edge dots at 1,024 elements.

The corpus found that Scatter Plot and Wave Dots placed the first and last dots partly outside
the canvas when there were more elements than horizontal pixels per six-point dot. Their Swift,
CPU Metal, and shader geometry now cap the diameter to the viewport and clamp the horizontal
center by the radius. The existing 64-element settled-image hashes remain unchanged.

Passing local runs:

| Target | Result bundle | Result |
| --- | --- | --- |
| BuiltInVisualizers, Catalyst | `/private/tmp/vis01-geometry-thin.xcresult` | Geometry corpus passed |
| BuiltInVisualizers, iPad mini simulator | `/private/tmp/vis01-ipad-geometry-thin.xcresult` | Geometry corpus passed |
| SortFeature, Catalyst | `/private/tmp/vis01-metal-3.xcresult` | 46 Metal render cases passed |
| SortFeature, iPad Air simulator | `/private/tmp/vis01-ipad-metal.xcresult` | 46 Metal render cases passed |
| SortFeature, Catalyst | `/private/tmp/vis01-parity.xcresult` | 32 Metal layout, buffer, and color cases passed |

The Metal device available to both Catalyst and the iPad simulators is the host Mac's Apple M5
Pro. Simulator model names do not establish another physical GPU family. On 2026-10-04, the
user accepted this hardware coverage as sufficient to close VIS-01 because these renderers do
not depend on specialized Metal features. A run on another physical family remains useful
release confidence, but is not evidence claimed by this verification.
