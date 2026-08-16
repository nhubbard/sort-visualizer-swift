#include <metal_stdlib>
#include "AnimatedField.h"
using namespace metal;

/// One wedge's raw underlying VALUE (+ its neighbor's, for the two layouts that need it) + color —
/// layout must match `MetalTriangleGPUInstance` exactly. `triangle_vertex` now derives all 3
/// points itself (`resolveTriangleGeometry`, selected per draw call by `uniforms.geometryKind`,
/// `MetalTriangleGeometryKind`'s cases) instead of reading 3 precomputed points — see
/// `MetalTriangleGPUInstance`'s own doc comment for why `previousValue` is supplied generically for
/// every layout, not just the two that read it.
struct TriangleInstance {
    int arrayIndex;
    AnimatedFloat value;
    AnimatedFloat previousValue;
    AnimatedColorSource color;
};

struct RasterizedTriangle {
    float4 position [[position]];
    float4 color;
};

/// One instanced draw call renders every wedge — `vertexID` (0/1/2) selects which of the 3 points
/// this vertex is, `.triangle` primitives (not `.triangleStrip`, unlike `shape_vertex`/`line_vertex`,
/// since there's no shared 4th corner to reuse across a strip when the points aren't a rectangle).
/// Resolving each animated field here AND deriving the actual 3 points from them
/// (`resolveAnimated`/`resolveTriangleGeometry`/`resolveAnimatedColorSource`, `AnimatedField.h`)
/// rather than on the CPU is what keeps steady-state per-frame CPU cost O(1) regardless of how
/// many wedges are mid-transition.
vertex RasterizedTriangle triangle_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant TriangleInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    TriangleInstance triangle = instances[instanceID];
    float value = resolveAnimated(triangle.value, uniforms.currentTime, uniforms.transitionDuration);
    float previousValue = resolveAnimated(
        triangle.previousValue, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedColorSource(
        triangle.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.useHueRamp,
        uniforms.primaryColor, uniforms.secondaryColor, uniforms.neutralColor);

    TriangleGeometry geometry = resolveTriangleGeometry(
        uniforms.geometryKind, triangle.arrayIndex, value, previousValue, uniforms.arrayCount,
        uniforms.valueRangeLowerBound, uniforms.valueRangeSpan, uniforms.viewportSize);

    float2 pixelPosition =
        vertexID == 0 ? geometry.p0 : (vertexID == 1 ? geometry.p1 : geometry.p2);

    // Same top-left-origin, +Y-down point space -> Metal NDC flip `bar_vertex`/`shape_vertex` use.
    float2 ndc = float2(
        (pixelPosition.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / uniforms.viewportSize.y) * 2.0
    );

    RasterizedTriangle out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = color;
    return out;
}

fragment float4 triangle_fragment(RasterizedTriangle in [[stage_in]]) {
    return in.color;
}

/// One chord's raw underlying VALUE + thickness + color — layout must match `MetalLineInstance`
/// exactly. `line_vertex` now derives both endpoints itself (`resolveChordGeometry`) instead of
/// reading 2 precomputed points — see `MetalLineInstance`'s own doc comment. `thickness` stays a
/// plain, unanimated scalar (never fed through a transition tracker on the Swift side either).
/// `DisparityChordsVisualizer` is the only line-based visualizer; a thin quad built from the
/// segment's own perpendicular is the standard "thick line" technique, same 4-corner
/// `.triangleStrip` shape `shape_vertex` uses for rects/ellipses.
struct LineInstance {
    AnimatedFloat value;
    float thickness;
    AnimatedColorSource color;
};

struct RasterizedLine {
    float4 position [[position]];
    float4 color;
};

vertex RasterizedLine line_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant LineInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    LineInstance line = instances[instanceID];
    float value = resolveAnimated(line.value, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedColorSource(
        line.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.useHueRamp,
        uniforms.primaryColor, uniforms.secondaryColor, uniforms.neutralColor);

    ChordGeometry geometry = resolveChordGeometry(
        int(instanceID), value, uniforms.arrayCount, uniforms.viewportSize);
    float2 start = geometry.start;
    float2 end = geometry.end;

    float2 direction = end - start;
    float length = max(metal::length(direction), 0.0001);
    // Perpendicular unit vector, scaled to half the line's thickness — offsetting each endpoint by
    // ± this is what turns a zero-width segment into a thin, correctly-oriented quad.
    float2 perpendicular = float2(-direction.y, direction.x) / length * (line.thickness * 0.5);

    // vertexID: 0=start-perp, 1=start+perp, 2=end-perp, 3=end+perp — matches `shape_vertex`'s own
    // `.triangleStrip` corner-ordering convention (2 pairs, strip connects them into 2 triangles).
    float2 base = (vertexID & 2) == 0 ? start : end;
    float2 pixelPosition = (vertexID & 1) == 0 ? base - perpendicular : base + perpendicular;

    float2 ndc = float2(
        (pixelPosition.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / uniforms.viewportSize.y) * 2.0
    );

    RasterizedLine out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = color;
    return out;
}

fragment float4 line_fragment(RasterizedLine in [[stage_in]]) {
    return in.color;
}
