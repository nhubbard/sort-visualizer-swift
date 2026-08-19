# Adding a visualizer

Adding a visualizer requires more work than adding an algorithm or a shuffle, for one structural
reason: the `Visualizer` protocol still defines the plugin boundary, but no code renders its
`[DrawCommand]` output. Every visualizer's on-screen geometry has a parallel Metal implementation
for performance (see [Architecture overview](../architecture/overview.md#rendering-metal-not-canvas)).
Shipping a new visualizer means writing that geometry twice: once as a plain, testable Swift
function (`Visualizer.draw(_:)`), and once as GPU-side geometry the Metal renderer draws. The two
must produce matching results.

## 1. Write the `Visualizer` conformance

Create a new file: `Modules/BuiltInVisualizers/Sources/<VisualizerName>Visualizer.swift`,
conforming to:

```swift
public protocol Visualizer: Sendable {
  var id: VisualizerID { get }
  var metadata: VisualizerMetadata { get }
  func draw(_ context: VisualizationContext) -> [DrawCommand]
}
```

Write `draw(_:)` as a small, pure, synchronous function. Existing visualizers run ten to twenty
lines. `VisualizationContext` provides `values`, `valueRange`, `markers` (index to active marker
IDs), `auxArrays`, `canvasSize`, and `colorSeed` (for deterministic per-run color choices, such as
a shuffled bucket-to-color map). It provides nothing about how the algorithm produced this frame.
Start from an existing visualizer with a similar shape:

- `BarGraphVisualizer` for a straightforward per-index rectangle layout.
- One of the `Disparity*Visualizer` family if your layout depends on a value's displacement from
  its sorted position, rather than its raw value.
- `HanoiTowersVisualizer` for an index-derived, rather than value-derived, layout.

This output is not vestigial, even though nothing renders it directly today. The visualizer's own
unit tests exercise it directly: feed a hand-built `VisualizationContext`, assert the expected
`[DrawCommand]`s. It is also the design source of truth the Metal geometry in step 3 must match.

## 2. Register the visualizer

There is a single call site: `App/Sources/Sort2App.swift`'s `VisualizerRegistry.shared.builtIns`
array. Add the new `Visualizer()` instantiation there. `VisualizationKit` has no visibility into
`BuiltInVisualizers` — that dependency edge runs the other way — so nothing populates the registry
automatically.

Unlike algorithms, visualizers have no second or third test-fixture list to update. No generic
cross-visualizer fuzz suite exists; each visualizer has only its own unit tests.

## 3. Port the geometry to Metal

This is the substantial work, and it lives in `Modules/SortFeature/Sources/`. The correct path
depends on your layout's shape:

- **Rectangle or ellipse-based layouts**, which cover most visualizers: conform to
  `MetalShapeLayout` (`MetalVisualizerLayouts.swift`) and add a case to `MetalShapeGeometryKind`
  (`MetalShapeGeometry.swift`). Your layout's `instance(atSlot:arrayIndex:values:valueRange:
  markers:)` computes only the slot's raw underlying value and color ingredients
  (`MetalShapeColor.normalized(value:in:)`/`.markerKind(forIndex:in:)`). Do not compute a resolved
  on-screen rect or a resolved color; the vertex shader resolves the geometry formula and final
  color, selected by your new `geometryKind` case, which you also write.
- **Triangle-fan or polygon-based layouts**, the circular and spiral layouts: conform to
  `MetalTriangleLayout` (`MetalPolygonVisualizerLayouts.swift`) instead. This follows the same
  pattern over a different geometry primitive.
- **Layouts unlike any existing pattern**, following the Hanoi Towers precedent: write a dedicated
  renderer conforming to `MetalIncrementalRenderer` directly, alongside `MetalHanoiTowersRenderer`
  as a working example. Use this path only when the geometry cannot reasonably be expressed as one
  more shader branch on the shared paths above.

Register your new renderer or layout in `MetalRendererFactory.makeRenderer(for:device:
sampleCount:)`, keyed by your visualizer's raw `VisualizerID` string. This is the single place that
maps a `VisualizerID` to its concrete Metal renderer.

Keep both sides of the geometry synchronized by hand. `MetalShapeGeometryKind`'s Swift enum raw
values must match the MSL `switch` cases in the shader's `resolveShapeGeometry` exactly. No shared
source of truth generates both. `MetalShapeGeometry.swift` carries a CPU-side reference
implementation of the same formula for tests, but a CPU-versus-CPU test cannot catch a bug in the
ported shader code.

## 4. Verify with pixel-readback tests

A resolved-instance test — comparing your layout's `instance(...)` output, or the CPU reference
geometry, against expected values — proves only that the Swift side is self-consistent. It cannot
catch a bug in the shader itself, such as a flipped comparison or a uniform that never reaches the
GPU. The established technique for that bug class is an offscreen-texture render plus a
`getBytes` pixel readback. See `MetalShapeColorResolutionPixelTests.swift` and
`MetalPolygonRendererTests` for the pattern; it has caught real bugs (a struct-layout mismatch
between a Swift vertex struct and its Metal-side counterpart) that no purely-Swift test detected.
Write at least one pixel-readback test for a new visualizer's geometry or color logic; do not rely
on resolved-instance assertions alone.

If you touch shared shader code, not just a new `geometryKind` branch, watch for a known bug
class: `setVertexBytes` calls must pass a Swift struct's `.stride`, never its `.size`. The two
differ once padding is involved. A `.size`-based call is invisible to every existing pixel-hash
test; it surfaces only under Metal API validation on a real device or simulator run. Run with
Metal API validation enabled at least once after changing a vertex buffer's struct layout.

## 5. Verify before finishing

- Run the full build and test suite for `BuiltInVisualizers` and `SortFeature`.
- Run the app and watch a sort through the new visualizer, at a small and a large array size, with
  markers active mid-comparison. A geometry bug at the boundary of the shader `switch` often
  appears only visually, not in a unit test.
- Check `git status`/`git diff --stat`. Expect the new `BuiltInVisualizers` source file, the
  `Sort2App.swift` registration, the new or edited layout type and shader branch under
  `Modules/SortFeature/Sources/`, and the new test file or files.
