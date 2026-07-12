/// Which pixel-pushing backend turns the current frame into what's on screen — orthogonal to
/// `VisualizerID` (which picks the *style*, e.g. bar graph vs. spiral). Deliberately a plain,
/// non-extensible enum rather than a `Visualizer`-style protocol + registry: this is an
/// experimental/diagnostic axis for comparing rendering strategies, not a third-party-pluggable
/// surface, and there will only ever be exactly these two.
///
/// A third case, `.cgContext` (a persistent `CGContext` bitmap repainted incrementally), was tried
/// and abandoned: once its rendering-orientation bug was fixed, it turned out to carry a severe,
/// unresolved performance regression relative to `.immediate` — not worth continuing to chase once
/// `.metal` already covers the same "incremental repaint" hypothesis without that cost.
///
/// `.metal` follows `AppSettings.selectedVisualizerID` like `.immediate` does, but only for the
/// styles `MetalRendererFactory` (in `SortFeature`) has an incremental GPU path for — each one
/// needs to know its touched positions' on-screen geometry directly, which only a taught
/// `MetalBarRenderer`/`MetalShapeLayout` conformance can do. `SortView.canvas(for:)` falls back to
/// `.immediate` automatically for any `Visualizer` without one.
public enum RendererBackendKind: String, CaseIterable, Codable, Sendable, Identifiable {
    /// The original, always-correct path: `Canvas` regenerates every draw command from the whole
    /// frame on every redraw. Works with any `Visualizer`.
    case immediate
    /// A persistent `MTLBuffer` of per-bar instance data, written incrementally (only the touched
    /// bars) via `ReplayEngine.onOperationApplied`, drawn via one instanced GPU draw call per frame.
    case metal

    public var id: Self { self }

    public var displayName: String {
        switch self {
        case .immediate: "Immediate Mode (Canvas)"
        case .metal: "Metal (Incremental)"
        }
    }
}
