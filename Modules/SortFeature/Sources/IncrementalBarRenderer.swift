import CoreGraphics
import SortEngineKit

/// A bar-graph-specific incremental renderer — see `RendererBackendKind`'s own doc comment
/// (`VisualizationKit`) for why this is scoped to one visualization style rather than going
/// through the general `Visualizer` protocol: `Visualizer.draw(_:) -> [DrawCommand]` is a pure
/// pull — "give me everything, every time" — with no way to say "only positions 3 and 7 changed
/// since you last asked." Getting genuine per-operation incremental repainting means knowing the
/// touched positions' on-screen geometry directly, which only this bar-graph-shaped conformance
/// is taught (matching `BarGraphVisualizer`'s own layout math exactly, so switching to an
/// incremental renderer looks the same on screen as switching to the "Bar Graph" style).
///
/// Deliberately does NOT unify "how to get pixels on screen" — `MetalBarRenderer` draws directly
/// to a drawable from `MTKView`'s own render callback, with nothing to hand back to a caller at
/// all. Only `apply`/`reset` — the incremental-update contract every backend that wants the
/// O(1)-per-operation property actually needs — is common enough to share.
@MainActor
protocol IncrementalBarRenderer: AnyObject {
    /// Full repaint from the current live state — the only path for the very first frame, a
    /// canvas resize, a new run starting at a different array size, and recovering from any state
    /// change that didn't arrive through `apply`. Scrubbing/seeking is the main example of the
    /// last case: `ReplayEngine.onStep`/`onOperationApplied` are both deliberately scoped to the
    /// `play()` loop only (see either one's doc comment), so a scrub never calls `apply` at all —
    /// callers must detect that `ReplayEngine.stepIndex` moved some other way and call `reset`.
    func reset(values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>], canvasSize: CGSize, scale: CGFloat)

    /// Incremental repaint for just the operation's touched positions — the fast path during
    /// normal playback, called once per operation via `ReplayEngine.onOperationApplied`. Values/
    /// markers reflect the CURRENT (post-batch) state, the same convention `AudioService.play`
    /// already relies on for the identical reason (see `onOperationApplied`'s doc comment).
    func apply(_ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>])
}
