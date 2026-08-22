#include <metal_stdlib>
#include "AnimatedField.h"
using namespace metal;

/// One bar's raw underlying VALUE + color, each field an unresolved `(from, to, startTime)`-shaped
/// triple instead of an already-interpolated value — `MetalBarRenderer` writes one of these
/// directly into a persistent buffer per touched index per operation, and this vertex shader
/// resolves the eased value/color AND derives the actual on-screen rect from them itself, every
/// frame (`resolveAnimated`/`resolveAnimatedMarkerColor`, `AnimatedField.h`) — geometry
/// (`barWidth`/`height`/`origin`/`size`) is no longer precomputed on the CPU at all, unlike every
/// other renderer's instance struct (which still stores an already-positioned rect). `color` is
/// `AnimatedMarkerColor`, not `AnimatedColorSource` — Bar never hue-ramps, only ever picks between
/// primary/secondary/a flat default. Layout must match `MetalBarRenderer.BarInstance` exactly
/// (both are plain, tightly-packed structs with no Swift-side padding surprises).
struct BarInstance {
    AnimatedFloat value;
    AnimatedMarkerColor color;
};

struct RasterizedBar {
    float4 position [[position]];
    float4 color;
};

/// One instanced draw call renders every bar — the GPU still redraws all of them every frame
/// regardless (that's the point: instanced GPU rectangle rendering is cheap enough at these array
/// sizes); the CPU-side buffer WRITE being incremental, in `MetalBarRenderer.apply`, is what
/// avoids the O(n) cost, and resolving each instance's animation here — instead of a CPU-side
/// per-frame sweep over every mid-fade slot — is what keeps the steady-state per-frame CPU cost
/// of an actively-animating scene at O(1) regardless of how many bars are mid-transition. Corner
/// selection via `vertex_id` avoids needing a separate vertex buffer for the shared unit quad.
///
/// Geometry (`barWidth`/`normalizedHeight`/`height`/`origin`/`size`) is computed HERE now, from
/// the eased raw `value` plus `uniforms.arrayCount`/`.valueRangeLowerBound`/`.valueRangeSpan` —
/// byte-for-byte the same formula `MetalBarRenderer.writeBar` used to run on the CPU once per
/// touched index per operation, just relocated to run once per vertex per frame instead. Easing
/// the raw value (not a precomputed position) is exact here since a bar's position is already a
/// LINEAR function of its value — no curve to diverge from, unlike the sin/cos-based visualizer
/// layouts a future port would need to accept a transition-path change for.
vertex RasterizedBar bar_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant BarInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    BarInstance bar = instances[instanceID];

    float value = resolveAnimated(bar.value, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedMarkerColor(
        bar.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.primaryColor,
        uniforms.secondaryColor, uniforms.neutralColor);

    float barWidth = uniforms.viewportSize.x / uniforms.arrayCount;
    float normalizedHeight = uniforms.valueRangeSpan > 0.0
        ? (value - uniforms.valueRangeLowerBound) / uniforms.valueRangeSpan
        : 1.0;
    float height = uniforms.viewportSize.y * normalizedHeight;
    // Top-left origin, bars anchored at the bottom — matches `BarGraphVisualizer` exactly (see
    // this function's own NDC-conversion comment below for how this point space maps over).
    float2 origin = float2(float(instanceID) * barWidth, uniforms.viewportSize.y - height);
    float2 size = float2(barWidth, height);

    float2 pixelPosition = origin + unitCorner * size;

    // Metal's NDC has +Y pointing up and spans [-1, 1]; our bar geometry is computed in the same
    // top-left-origin, +Y-down point space `BarGraphVisualizer`/`CGContextBarRenderer` use, so
    // this flips Y during the pixel -> NDC conversion rather than needing the CPU side to.
    float2 ndc = float2(
        (pixelPosition.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / uniforms.viewportSize.y) * 2.0
    );

    RasterizedBar out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = color;
    return out;
}

fragment float4 bar_fragment(RasterizedBar in [[stage_in]]) {
    return in.color;
}
