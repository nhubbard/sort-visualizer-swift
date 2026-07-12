#include <metal_stdlib>
using namespace metal;

/// One triangle's 3 explicit points + color, in points (not normalized) — layout must match
/// `MetalTriangleInstance` exactly. Unlike `ShapeInstance`'s bounding-box + fragment-mask approach
/// (`ShapeRenderer.metal`), the wedge visualizers (`ColorCircle`/`DisparityCircle`/`Spiral`) already
/// compute 3 explicit points each (`[center, previousPoint, currentPoint]`), so there's no bounding
/// box to derive a mask from — the vertex shader just places each point directly.
struct TriangleInstance {
    float2 p0;
    float2 p1;
    float2 p2;
    float4 color;
};

struct RasterizedTriangle {
    float4 position [[position]];
    float4 color;
};

/// One instanced draw call renders every wedge — `vertexID` (0/1/2) selects which of the 3 points
/// this vertex is, `.triangle` primitives (not `.triangleStrip`, unlike `shape_vertex`/`line_vertex`,
/// since there's no shared 4th corner to reuse across a strip when the points aren't a rectangle).
vertex RasterizedTriangle triangle_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant TriangleInstance *instances [[buffer(0)]],
    constant float2 &viewportSize [[buffer(1)]]
) {
    TriangleInstance triangle = instances[instanceID];
    float2 pixelPosition = vertexID == 0 ? triangle.p0 : (vertexID == 1 ? triangle.p1 : triangle.p2);

    // Same top-left-origin, +Y-down point space -> Metal NDC flip `bar_vertex`/`shape_vertex` use.
    float2 ndc = float2(
        (pixelPosition.x / viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / viewportSize.y) * 2.0
    );

    RasterizedTriangle out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = triangle.color;
    return out;
}

fragment float4 triangle_fragment(RasterizedTriangle in [[stage_in]]) {
    return in.color;
}

/// One line segment's endpoints + thickness + color, in points — layout must match
/// `MetalLineInstance` exactly. `DisparityChordsVisualizer` is the only line-based visualizer; a
/// thin quad built from the segment's own perpendicular is the standard "thick line" technique,
/// same 4-corner `.triangleStrip` shape `shape_vertex` uses for rects/ellipses.
struct LineInstance {
    float2 start;
    float2 end;
    float thickness;
    float4 color;
};

struct RasterizedLine {
    float4 position [[position]];
    float4 color;
};

vertex RasterizedLine line_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant LineInstance *instances [[buffer(0)]],
    constant float2 &viewportSize [[buffer(1)]]
) {
    LineInstance line = instances[instanceID];
    float2 direction = line.end - line.start;
    float length = max(metal::length(direction), 0.0001);
    // Perpendicular unit vector, scaled to half the line's thickness — offsetting each endpoint by
    // ± this is what turns a zero-width segment into a thin, correctly-oriented quad.
    float2 perpendicular = float2(-direction.y, direction.x) / length * (line.thickness * 0.5);

    // vertexID: 0=start-perp, 1=start+perp, 2=end-perp, 3=end+perp — matches `shape_vertex`'s own
    // `.triangleStrip` corner-ordering convention (2 pairs, strip connects them into 2 triangles).
    float2 base = (vertexID & 2) == 0 ? line.start : line.end;
    float2 pixelPosition = (vertexID & 1) == 0 ? base - perpendicular : base + perpendicular;

    float2 ndc = float2(
        (pixelPosition.x / viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / viewportSize.y) * 2.0
    );

    RasterizedLine out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = line.color;
    return out;
}

fragment float4 line_fragment(RasterizedLine in [[stage_in]]) {
    return in.color;
}
