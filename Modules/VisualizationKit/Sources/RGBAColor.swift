public struct RGBAColor: Sendable, Codable, Equatable {
  public var red: Double
  public var green: Double
  public var blue: Double
  public var alpha: Double

  public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  /// Derive a color purely from a value's position in a range — no per-element state to store,
  /// matches how most of ArrayV's 15 visualization styles pick color.
  public static func hueRamp(_ position: Double) -> RGBAColor {
    let clamped = max(0, min(1, position))
    // Sweep red -> violet (0...0.8), rather than the full 0...1 circle, so the two ends of the
    // range are visually distinct instead of both landing on red.
    let (r, g, b) = hsvToRGB(hue: clamped * 0.8, saturation: 0.8, value: 0.9)
    return RGBAColor(red: r, green: g, blue: b)
  }

  private static func hsvToRGB(hue: Double, saturation: Double, value: Double) -> (
    Double, Double, Double
  ) {
    let sector = Int(hue * 6)
    let fraction = hue * 6 - Double(sector)
    let p = value * (1 - saturation)
    let q = value * (1 - fraction * saturation)
    let t = value * (1 - (1 - fraction) * saturation)
    switch sector % 6 {
    case 0: return (value, t, p)
    case 1: return (q, value, p)
    case 2: return (p, value, t)
    case 3: return (p, q, value)
    case 4: return (t, p, value)
    default: return (value, p, q)
    }
  }
}
