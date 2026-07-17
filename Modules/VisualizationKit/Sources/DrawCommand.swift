/// Inert `Codable` data — a case, some doubles, a color — never a view. `Visualizer.draw(_:)`'s
/// return type: every built-in visualizer's own tests exercise this directly, and each Metal
/// renderer's `MetalShapeLayout`/`MetalTriangleLayout`/etc. conformance was ported from this exact
/// math, even though nothing renders a `[DrawCommand]` on screen anymore (§2A.3).
public enum DrawCommand: Sendable, Codable, Equatable {
  case rect(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
  case ellipse(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
  case line(x1: Double, y1: Double, x2: Double, y2: Double, color: RGBAColor, lineWidth: Double)
  case polygon(points: [SIMD2<Double>], color: RGBAColor)
  case text(x: Double, y: Double, string: String, color: RGBAColor)
}
