/// Inert `Codable` data — a case, some doubles, a color — never a view. `VisualizationCanvas`'s
/// `Canvas { context, size in ... }` closure just switches over a `[DrawCommand]` and calls the
/// matching `GraphicsContext.fill`/`.stroke`/`.draw(Text)` method (§2A.3).
public enum DrawCommand: Sendable, Codable, Equatable {
    case rect(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
    case ellipse(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
    case line(x1: Double, y1: Double, x2: Double, y2: Double, color: RGBAColor, lineWidth: Double)
    case polygon(points: [SIMD2<Double>], color: RGBAColor)
    case text(x: Double, y: Double, string: String, color: RGBAColor)
}
