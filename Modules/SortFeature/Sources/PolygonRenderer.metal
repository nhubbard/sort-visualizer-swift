#include <metal_stdlib>
#include "AnimatedField.h"
using namespace metal;

/// One triangle's 3 explicit points + color, each field an unresolved `(from, to, startTime)`
/// triple — layout must match `MetalTriangleGPUInstance` exactly. Unlike `ShapeInstance`'s
/// bounding-box + fragment-mask approach (`ShapeRenderer.metal`), the wedge visualizers
/// (`ColorCircle`/`DisparityCircle`/`Spiral`) already compute 3 explicit points each (`[center,
/// previousPoint, currentPoint]`), so there's no bounding box to derive a mask from — the vertex
/// shader just places each resolved point directly.
struct TriangleInstance {
    AnimatedFloat2 p0;
    AnimatedFloat2 p1;
    AnimatedFloat2 p2;
    AnimatedColorSource color;
};

struct RasterizedTriangle {
    float4 position [[position]];
    float4 color;
};

/// One instanced draw call renders every wedge — `vertexID` (0/1/2) selects which of the 3 points
/// this vertex is, `.triangle` primitives (not `.triangleStrip`, unlike `shape_vertex`/`line_vertex`,
/// since there's no shared 4th corner to reuse across a strip when the points aren't a rectangle).
/// Resolving each point/the color here (`resolveAnimated2`/`resolveAnimated4`, `AnimatedField.h`)
/// rather than on the CPU is what keeps steady-state per-frame CPU cost O(1) regardless of how
/// many wedges are mid-transition.
vertex RasterizedTriangle triangle_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant TriangleInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    TriangleInstance triangle = instances[instanceID];
    float2 p0 = resolveAnimated2(triangle.p0, uniforms.currentTime, uniforms.transitionDuration);
    float2 p1 = resolveAnimated2(triangle.p1, uniforms.currentTime, uniforms.transitionDuration);
    float2 p2 = resolveAnimated2(triangle.p2, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedColorSource(
        triangle.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.useHueRamp,
        uniforms.primaryColor, uniforms.secondaryColor, uniforms.neutralColor);

    float2 pixelPosition = vertexID == 0 ? p0 : (vertexID == 1 ? p1 : p2);

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

/// One line segment's endpoints + thickness + color, in points — `start`/`end`/`color` are
/// unresolved `(from, to, startTime)` triples; `thickness` stays a plain, unanimated scalar
/// (never fed through a transition tracker on the Swift side either). Layout must match
/// `MetalLineInstance` exactly. `DisparityChordsVisualizer` is the only line-based visualizer; a
/// thin quad built from the segment's own perpendicular is the standard "thick line" technique,
/// same 4-corner `.triangleStrip` shape `shape_vertex` uses for rects/ellipses.
struct LineInstance {
    AnimatedFloat2 start;
    AnimatedFloat2 end;
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
    float2 start = resolveAnimated2(line.start, uniforms.currentTime, uniforms.transitionDuration);
    float2 end = resolveAnimated2(line.end, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedColorSource(
        line.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.useHueRamp,
        uniforms.primaryColor, uniforms.secondaryColor, uniforms.neutralColor);

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
