#include <metal_stdlib>
using namespace metal;

/// One shape's on-screen rect + color, in points (not normalized) — layout must match
/// `MetalShapeInstance` exactly (both are plain, tightly-packed float structs with no Swift-side
/// padding surprises). Reused for both `.rect` and `.ellipse` `MetalShapeLayout`s: the bounding box
/// is identical either way, only the fragment shader differs in whether it fills the whole box or
/// masks it to the ellipse inscribed within it.
struct ShapeInstance {
    float2 origin;
    float2 size;
    float4 color;
};

struct RasterizedShape {
    float4 position [[position]];
    float4 color;
    // -1...1 across the instance's own bounding box, centered at its origin — `rect_fragment`
    // ignores this; `ellipse_fragment` uses it for the inscribed-ellipse distance test.
    float2 localUV;
};

/// Same one-instanced-draw-call-per-frame structure as `bar_vertex` (see its own doc comment) —
/// this is a separate function rather than a shared one only because it additionally computes
/// `localUV`, which `bar_vertex`'s `RasterizedBar` output has no field for.
vertex RasterizedShape shape_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant ShapeInstance *instances [[buffer(0)]],
    constant float2 &viewportSize [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    ShapeInstance shape = instances[instanceID];
    float2 pixelPosition = shape.origin + unitCorner * shape.size;

    // Same top-left-origin, +Y-down point space -> Metal NDC flip `bar_vertex` uses.
    float2 ndc = float2(
        (pixelPosition.x / viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / viewportSize.y) * 2.0
    );

    RasterizedShape out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = shape.color;
    out.localUV = unitCorner * 2.0 - 1.0;
    return out;
}

fragment float4 rect_fragment(RasterizedShape in [[stage_in]]) {
    return in.color;
}

/// Discards fragments outside the ellipse inscribed in the instance's bounding box — `localUV` is
/// already normalized to that box, so a plain unit-circle distance test in UV space traces the
/// box's actual ellipse (not just a circle) regardless of the box's aspect ratio.
fragment float4 ellipse_fragment(RasterizedShape in [[stage_in]]) {
    if (dot(in.localUV, in.localUV) > 1.0) {
        discard_fragment();
    }
    return in.color;
}
