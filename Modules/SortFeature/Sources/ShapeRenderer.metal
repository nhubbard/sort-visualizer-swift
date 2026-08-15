#include <metal_stdlib>
#include "AnimatedField.h"
using namespace metal;

/// One shape's on-screen rect + color, each field an unresolved `(from, to, startTime)` triple —
/// layout must match `MetalShapeGPUInstance` exactly. Reused for both `.rect` and `.ellipse`
/// `MetalShapeLayout`s: the bounding box is identical either way, only the fragment shader differs
/// in whether it fills the whole box or masks it to the ellipse inscribed within it.
struct ShapeInstance {
    AnimatedFloat2 origin;
    AnimatedFloat2 size;
    AnimatedFloat4 color;
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
/// `localUV`, which `bar_vertex`'s `RasterizedBar` output has no field for. Resolving each
/// animated field here (`resolveAnimated2`/`resolveAnimated4`, `AnimatedField.h`) rather than on
/// the CPU is what keeps steady-state per-frame CPU cost O(1) regardless of how many shapes are
/// mid-transition — see `MetalColorTransitionTracker`'s doc comment for the full rationale.
vertex RasterizedShape shape_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant ShapeInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    ShapeInstance shape = instances[instanceID];

    float2 origin = resolveAnimated2(shape.origin, uniforms.currentTime, uniforms.transitionDuration);
    float2 size = resolveAnimated2(shape.size, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimated4(shape.color, uniforms.currentTime, uniforms.transitionDuration);

    float2 pixelPosition = origin + unitCorner * size;

    // Same top-left-origin, +Y-down point space -> Metal NDC flip `bar_vertex` uses.
    float2 ndc = float2(
        (pixelPosition.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / uniforms.viewportSize.y) * 2.0
    );

    RasterizedShape out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = color;
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

/// `MetalHanoiTowersRenderer`'s fixed 2-leg animated origin — layout must match Swift's
/// `HanoiOrigin` (`HanoiMoveScheduler.swift`) exactly. Not in `AnimatedField.h`: unlike that
/// header's genuinely shared primitives, this shape is specific to Hanoi's choreography, so it
/// lives alongside its only consumer, `hanoi_vertex`, below.
struct HanoiOrigin {
    float2 leg0From;
    float2 leg0To;
    float2 leg1To;
    float leg0Hold;
    float startTime;
};

/// Layout must match Swift's `HanoiInstance` (`MetalHanoiTowersRenderer.swift`) exactly — `size`
/// is a plain unanimated `float2` (Hanoi never eases block size), `color` is the usual
/// `AnimatedFloat4`.
struct HanoiInstance {
    HanoiOrigin origin;
    float2 size;
    AnimatedFloat4 color;
};

/// Resolves a `HanoiOrigin` to its current displayed position — the shader-side counterpart to
/// `HanoiMoveScheduler.resolvedOrigin(forSlot:now:)`, which MUST stay in sync with this exactly
/// (that Swift copy runs only at retarget time, to compute a smooth continuation point; this one
/// runs every frame, for every Hanoi instance, which is the entire point of the GPU-driven
/// redesign — see `MetalColorTransitionTracker`'s doc comment). Reproduces the exact two-phase
/// timing `HanoiMoveScheduler`'s doc comment describes: ease `transitionDuration` toward `leg0To`,
/// sit static until `leg0Hold` elapses, then ease a fresh `transitionDuration` toward `leg1To` —
/// NOT a single fade lasting `leg0Hold`, which is why `t` is compared against `leg0Hold` directly
/// rather than folded into `transitionDuration`.
inline float2 resolveHanoiOrigin(HanoiOrigin o, float currentTime, float transitionDuration) {
    float t = currentTime - o.startTime;
    if (t < o.leg0Hold) {
        float localT = clamp(t / transitionDuration, 0.0, 1.0);
        return mix(o.leg0From, o.leg0To, easeInOutCubic(localT));
    } else {
        float localT = clamp((t - o.leg0Hold) / transitionDuration, 0.0, 1.0);
        return mix(o.leg0To, o.leg1To, easeInOutCubic(localT));
    }
}

/// Same one-instanced-draw-call structure as `shape_vertex` — the only genuine difference is
/// `origin`'s resolution, via `resolveHanoiOrigin` above instead of the shared `resolveAnimated2`,
/// to reproduce the fixed 2-leg choreography. Reuses `RasterizedShape`/`rect_fragment` unchanged:
/// a Hanoi Towers block is just a rect once its origin is resolved, no new fragment stage needed.
vertex RasterizedShape hanoi_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant HanoiInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    HanoiInstance block = instances[instanceID];

    float2 origin = resolveHanoiOrigin(block.origin, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimated4(block.color, uniforms.currentTime, uniforms.transitionDuration);

    float2 pixelPosition = origin + unitCorner * block.size;

    float2 ndc = float2(
        (pixelPosition.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixelPosition.y / uniforms.viewportSize.y) * 2.0
    );

    RasterizedShape out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = color;
    out.localUV = unitCorner * 2.0 - 1.0;
    return out;
}
