#include <metal_stdlib>
using namespace metal;

/// One bar's on-screen rect + color, in points (not normalized) — `MetalBarRenderer` writes
/// directly into a persistent buffer of these, one write per touched index per operation, rather
/// than rebuilding the whole buffer every frame. Layout must match `MetalBarRenderer.BarInstance`
/// exactly (both are plain, tightly-packed float structs with no Swift-side padding surprises).
struct BarInstance {
    float2 origin;
    float2 size;
    float4 color;
};

struct RasterizedBar {
    float4 position [[position]];
    float4 color;
};

/// One instanced draw call renders every bar — the GPU redraws all of them every frame
/// regardless (that's the point: instanced GPU rectangle rendering is cheap enough at these array
/// sizes that redrawing everything every frame isn't the bottleneck; the CPU-side buffer WRITE
/// being incremental, in `MetalBarRenderer.apply`, is what actually avoids the O(n) cost). Corner
/// selection via `vertex_id` avoids needing a separate vertex buffer for the shared unit quad.
vertex RasterizedBar bar_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant BarInstance *instances [[buffer(0)]],
    constant float2 &viewportSize [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    BarInstance bar = instances[instanceID];
    float2 pixelPosition = bar.origin + unitCorner * bar.size;

    // Metal's NDC has +Y pointing up and spans [-1, 1]; our bar geometry is computed in the same
    // top-left-origin, +Y-down point space `BarGraphVisualizer`/`CGContextBarRenderer` use, so
    // this flips Y during the pixel -> NDC conversion rather than needing the CPU side to.
    float2 ndc = float2(
        (pixelPosition.x / viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / viewportSize.y) * 2.0
    );

    RasterizedBar out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = bar.color;
    return out;
}

fragment float4 bar_fragment(RasterizedBar in [[stage_in]]) {
    return in.color;
}
