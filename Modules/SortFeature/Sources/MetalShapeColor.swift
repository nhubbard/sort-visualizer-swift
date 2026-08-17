import SortEngineKit
import VisualizationKit

/// Shared marker-aware coloring for every `MetalShapeLayout` — every ported `Visualizer` follows
/// the exact same "primary/secondary marker overrides everything else" rule with the exact same
/// two marker colors, so this exists once here instead of being hand-copied into each layout.
enum MetalShapeColor {
  static let primary = SIMD4<Float>(0.95, 0.38, 0.38, 1)
  static let secondary = SIMD4<Float>(0.38, 0.58, 0.95, 1)
  /// `ScatterPlotVisualizer`/`WaveDotsVisualizer`'s flat, non-hue-ramped default. `var`, not
  /// `let`, for the same light/dark-mode reason as `MetalBarRenderer.defaultColor`.
  /// `nonisolated(unsafe)`: every actual reader/writer runs on the main thread by construction
  /// (this whole pipeline is driven by an `isPaused`/`enableSetNeedsDisplay` `MTKView` from
  /// main-thread callbacks), but this enum's other static methods are called from genuinely
  /// `nonisolated` layout contexts, so `@MainActor` isolation isn't an option here.
  nonisolated(unsafe) static var neutral = SIMD4<Float>(0.82, 0.82, 0.86, 1)

  /// A compact `0`/`1`/`2` kind instead of a resolved color, matching `Marker.primary`/`Marker
  /// .secondary`'s own raw values exactly so no separate mapping table is needed —
  /// `AnimatedField.h`'s `resolveColorSource` checks this directly against the same two raw
  /// integers. `0` means "no marker" — every renderer now passes this (plus a raw value, for
  /// hue-ramp-capable renderers) instead of a resolved `SIMD4<Float>` color, since color
  /// resolution moved into the vertex shader.
  static func markerKind(forIndex index: Int, in markers: [Int: Set<Int>]) -> Int32 {
    // `isEmpty` is a plain property read, no hashing — skips the Dictionary subscript's hash +
    // bucket probe entirely for the common case (most operations mark nothing at all, or mark far
    // fewer indices than a renderer repaints per operation — e.g. Hanoi's obstacle writes, which a
    // real trace found spending real main-thread time in exactly this lookup).
    guard !markers.isEmpty else { return 0 }
    let indexMarkers = markers[index] ?? []
    if indexMarkers.contains(Marker.primary) { return Int32(Marker.primary) }
    if indexMarkers.contains(Marker.secondary) { return Int32(Marker.secondary) }
    return 0
  }

  static func hueRamp(_ normalized: Double) -> SIMD4<Float> {
    let color = RGBAColor.hueRamp(normalized)
    return SIMD4(Float(color.red), Float(color.green), Float(color.blue), Float(color.alpha))
  }

  static func normalized(value: Int, in valueRange: ClosedRange<Int>) -> Double {
    let spanLength = Double(valueRange.upperBound - valueRange.lowerBound)
    return spanLength > 0 ? Double(value - valueRange.lowerBound) / spanLength : 1.0
  }
}
