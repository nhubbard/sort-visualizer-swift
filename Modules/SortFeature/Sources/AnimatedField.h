#ifndef AnimatedField_h
#define AnimatedField_h

#include <metal_stdlib>
using namespace metal;

/// Layout-matched to `MetalAnimatedField.swift`'s `MetalAnimationUniforms` — both are plain,
/// tightly-packed structs with no padding surprises (the same Swift/MSL layout-equivalence this
/// codebase already relied on for `LineInstance`'s interleaved float2/float/float4 fields, now
/// extended to these animation structs). One instance filled and uploaded per frame via
/// `setVertexBytes`, buffer index 1 — the only per-frame CPU cost animation has left anywhere.
struct AnimationUniforms {
    float2 viewportSize;
    float currentTime;
    float transitionDuration;
};

/// Layout-matched to `MetalAnimatedField.swift`'s `AnimatedFloat2` — the explicit `_padding`
/// field is load-bearing, not cosmetic: see that Swift struct's own doc comment for the real bug
/// (Swift vs. MSL disagreeing on nested-struct field packing) this padding exists to eliminate.
struct AnimatedFloat2 {
    float2 from;
    float2 to;
    float startTime;
    float _padding;
};

/// Layout-matched to `MetalAnimatedField.swift`'s `AnimatedFloat4`. See `AnimatedFloat2`'s own
/// comment for why the explicit padding is load-bearing.
struct AnimatedFloat4 {
    float4 from;
    float4 to;
    float startTime;
    float _padding0;
    float _padding1;
    float _padding2;
};

/// Byte-for-byte port of `MetalColorTransitionTracker.swift`'s file-scope `easeInOutCubic(_:)` —
/// must stay in sync with that Swift implementation (also mirrored by each transition tracker's
/// private CPU-side `resolvedValue`, used only at retarget time, never per frame). The `t < 0.5`
/// branch direction is flipped relative to the Swift version's `t >= 0.5` guard, but both formulas
/// agree exactly at `t == 0.5`, so this is not a behavior difference.
inline float easeInOutCubic(float t) {
    if (t < 0.5) {
        return 4.0 * t * t * t;
    }
    float f = -2.0 * t + 2.0;
    return 1.0 - f * f * f / 2.0;
}

/// Resolves an `AnimatedFloat2` to its current eased value — called once per animated field per
/// vertex, replacing what used to be a CPU-side `advance(elapsed:)` sweep over every active
/// transition once per frame. `from == to` (a slot's first-ever paint) resolves to that same value
/// regardless of `t`, matching `valueToWrite`'s "shows immediately, no fade" contract with no
/// special-casing needed here.
inline float2 resolveAnimated2(AnimatedFloat2 field, float currentTime, float duration) {
    float t = clamp((currentTime - field.startTime) / duration, 0.0, 1.0);
    return mix(field.from, field.to, easeInOutCubic(t));
}

/// The color counterpart to `resolveAnimated2`.
inline float4 resolveAnimated4(AnimatedFloat4 field, float currentTime, float duration) {
    float t = clamp((currentTime - field.startTime) / duration, 0.0, 1.0);
    return mix(field.from, field.to, easeInOutCubic(t));
}

#endif /* AnimatedField_h */
