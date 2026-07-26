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

  /// `nil` when `index` carries no marker at all — callers fall back to whatever
  /// non-marker color their own `Visualizer` used (`hueRamp` for most, `neutral` for the two
  /// that don't hue-ramp).
  static func marker(forIndex index: Int, in markers: [Int: Set<Int>]) -> SIMD4<Float>? {
    let indexMarkers = markers[index] ?? []
    if indexMarkers.contains(Marker.primary) { return primary }
    if indexMarkers.contains(Marker.secondary) { return secondary }
    return nil
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
