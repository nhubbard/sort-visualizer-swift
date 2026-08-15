#include <metal_stdlib>
#include "AnimatedField.h"
using namespace metal;

/// One bar's on-screen rect + color, each field an unresolved `(from, to, startTime)`-shaped
/// triple instead of an already-interpolated value — `MetalBarRenderer` writes one of these
/// directly into a persistent buffer per touched index per operation, and this vertex shader
/// resolves the actual displayed geometry/color itself, every frame, via `resolveAnimated2`/
/// `resolveAnimatedMarkerColor` (`AnimatedField.h`). `color` is `AnimatedMarkerColor`, not
/// `AnimatedColorSource` — Bar never hue-ramps, only ever picks between primary/secondary/a flat
/// default. Layout must match `MetalBarRenderer.BarInstance` exactly (both are plain,
/// tightly-packed structs with no Swift-side padding surprises).
struct BarInstance {
    AnimatedFloat2 origin;
    AnimatedFloat2 size;
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
vertex RasterizedBar bar_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant BarInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    BarInstance bar = instances[instanceID];

    float2 origin = resolveAnimated2(bar.origin, uniforms.currentTime, uniforms.transitionDuration);
    float2 size = resolveAnimated2(bar.size, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedMarkerColor(
        bar.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.primaryColor,
        uniforms.secondaryColor, uniforms.neutralColor);

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
