#include <metal_stdlib>
#include "AnimatedField.h"
using namespace metal;

/// One shape's raw underlying VALUE + color, each animated field an unresolved
/// `(from, to, startTime)` triple — layout must match `MetalShapeGPUInstance` exactly. Reused for
/// both `.rect` and `.ellipse` `MetalShapeLayout`s: `resolveShapeGeometry` computes the correct
/// bounding box either way (which fragment shader gets used — `rect_fragment` vs
/// `ellipse_fragment` — is what actually distinguishes them at draw time, via `MetalShapeRenderer
/// .init?`'s pipeline setup, not anything here). `arrayIndex` is a plain, unanimated `int` — see
/// `MetalShapeGPUInstance`'s own doc comment.
struct ShapeInstance {
    int arrayIndex;
    AnimatedFloat value;
    AnimatedColorSource color;
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
/// animated field here (`resolveAnimated`/`resolveAnimatedColorSource`, `AnimatedField.h`) AND
/// deriving the actual on-screen rect from the resolved value (`resolveShapeGeometry`, selected
/// per draw call by `uniforms.geometryKind`) rather than on the CPU is what keeps steady-state
/// per-frame CPU cost O(1) regardless of how many shapes are mid-transition — see
/// `MetalColorSourceTracker`'s doc comment for the full rationale.
vertex RasterizedShape shape_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant ShapeInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    ShapeInstance shape = instances[instanceID];

    float value = resolveAnimated(shape.value, uniforms.currentTime, uniforms.transitionDuration);
    float4 color = resolveAnimatedColorSource(
        shape.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.useHueRamp,
        uniforms.primaryColor, uniforms.secondaryColor, uniforms.neutralColor);

    ShapeGeometry geometry = resolveShapeGeometry(
        uniforms.geometryKind, int(instanceID), shape.arrayIndex, value, uniforms.arrayCount,
        uniforms.valueRangeLowerBound, uniforms.valueRangeSpan, uniforms.viewportSize,
        uniforms.scale);

    float2 pixelPosition = geometry.origin + unitCorner * geometry.size;

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

/// Layout must match Swift's `HanoiInstance` (`MetalHanoiTowersRenderer.swift`) exactly — no
/// `size` field anymore: `hanoi_vertex` now derives the on-screen rect itself (`resolveHanoiGeometry`
/// below) from `origin`'s resolved (tower, depth) coordinate, the same "raw ingredients only" shape
/// every other GPU-geometry port already uses. `color` is the usual `AnimatedColorSource` (Hanoi
/// hue-ramps like every renderer except `MetalBarRenderer`).
struct HanoiInstance {
    HanoiOrigin origin;
    AnimatedColorSource color;
};

/// Resolves a `HanoiOrigin` to its current (tower, depth) COORDINATE — NOT a pixel position
/// anymore; see `resolveHanoiGeometry` below for the formula that turns this into one. The
/// shader-side counterpart to `HanoiMoveScheduler.resolvedOrigin(forSlot:now:)`, which MUST stay in
/// sync with this exactly (that Swift copy runs only at retarget time, to compute a smooth
/// continuation point; this one runs every frame, for every Hanoi instance, which is the entire
/// point of the GPU-driven redesign — see `MetalColorSourceTracker`'s doc comment). Reproduces the
/// exact two-phase timing `HanoiMoveScheduler`'s doc comment describes: ease `transitionDuration`
/// toward `leg0To`, sit static until `leg0Hold` elapses, then ease a fresh `transitionDuration`
/// toward `leg1To` — NOT a single fade lasting `leg0Hold`, which is why `t` is compared against
/// `leg0Hold` directly rather than folded into `transitionDuration`.
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

/// MSL port of `MetalHanoiGeometry.swift`'s `hanoiTowerCount`/`resolveHanoiGeometry` — MUST stay
/// formula-for-formula in sync with that Swift pair. See that file's own doc comments for the full
/// rationale (why a (tower, depth) coordinate rather than a pixel position can be blended by
/// `resolveHanoiOrigin` above and still produce the exact same result as blending pixel positions
/// directly, and why Metal's `round()` matching Swift's `.rounded()` matters here).
inline float hanoiTowerCount(float arrayCount) {
    float raw = round(sqrt(arrayCount));
    return clamp(raw, 3.0, 8.0);
}

struct HanoiGeometry {
    float2 origin;
    float2 size;
};

inline HanoiGeometry resolveHanoiGeometry(float2 towerDepth, float arrayCount, float2 viewportSize) {
    float towerCount = hanoiTowerCount(arrayCount);
    float maxDepth = max(1.0, ceil(arrayCount / towerCount));
    float towerWidth = viewportSize.x / towerCount;
    float blockHeight = viewportSize.y / maxDepth;
    HanoiGeometry result;
    result.origin = float2(
        towerDepth.x * towerWidth + towerWidth * 0.1,
        viewportSize.y - (towerDepth.y + 1.0) * blockHeight);
    result.size = float2(towerWidth * 0.8, blockHeight * 0.9);
    return result;
}

/// Same one-instanced-draw-call structure as `shape_vertex` — the only genuine difference is
/// `origin`'s resolution, via `resolveHanoiOrigin`/`resolveHanoiGeometry` above instead of the
/// shared `resolveAnimated2`/`resolveShapeGeometry`, to reproduce the fixed 2-leg choreography.
/// Reuses `RasterizedShape`/`rect_fragment` unchanged: a Hanoi Towers block is just a rect once its
/// origin is resolved, no new fragment stage needed.
vertex RasterizedShape hanoi_vertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant HanoiInstance *instances [[buffer(0)]],
    constant AnimationUniforms &uniforms [[buffer(1)]]
) {
    float2 unitCorner = float2(float(vertexID & 1), float(vertexID >> 1));
    HanoiInstance block = instances[instanceID];

    float2 towerDepth = resolveHanoiOrigin(block.origin, uniforms.currentTime, uniforms.transitionDuration);
    HanoiGeometry geometry = resolveHanoiGeometry(towerDepth, uniforms.arrayCount, uniforms.viewportSize);
    float4 color = resolveAnimatedColorSource(
        block.color, uniforms.currentTime, uniforms.transitionDuration, uniforms.useHueRamp,
        uniforms.primaryColor, uniforms.secondaryColor, uniforms.neutralColor);

    float2 pixelPosition = geometry.origin + unitCorner * geometry.size;

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
