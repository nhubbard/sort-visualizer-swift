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
    float useHueRamp;
    float4 primaryColor;
    float4 secondaryColor;
    float4 neutralColor;
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

/// Byte-for-byte port of `MetalEasingCore.swift`'s file-scope `easeInOutCubic(_:)` —
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

/// Layout-matched to `MetalAnimatedField.swift`'s `AnimatedColorSource` — raw `(value, marker)`
/// ingredients at each end of a fade instead of precomputed RGBA. Every field is a plain 4-byte
/// scalar (no `float2`/`float4` members), so this struct's raw size is already a multiple of its
/// own alignment — none of `AnimatedFloat2`'s padding risk applies here.
struct AnimatedColorSource {
    float fromValue;
    int fromMarker;
    float toValue;
    int toMarker;
    float startTime;
};

/// Layout-matched to `MetalAnimatedField.swift`'s `AnimatedMarkerColor` — `MetalBarRenderer`'s
/// simpler marker-only color source (no hue-ramp `value` at all).
struct AnimatedMarkerColor {
    int fromMarker;
    int toMarker;
    float startTime;
};

/// Port of `RGBAColor.hsvToRGB` (`Modules/VisualizationKit/Sources/RGBAColor.swift`) — MUST stay
/// byte-for-byte in sync with that Swift implementation, the same way `easeInOutCubic` above does.
inline float3 hsvToRGB(float hue, float saturation, float value) {
    int sector = int(hue * 6.0);
    float fraction = hue * 6.0 - float(sector);
    float p = value * (1.0 - saturation);
    float q = value * (1.0 - fraction * saturation);
    float t = value * (1.0 - (1.0 - fraction) * saturation);
    switch (sector % 6) {
        case 0: return float3(value, t, p);
        case 1: return float3(q, value, p);
        case 2: return float3(p, value, t);
        case 3: return float3(p, q, value);
        case 4: return float3(t, p, value);
        default: return float3(value, p, q);
    }
}

/// Port of `RGBAColor.hueRamp(_:)` — MUST stay byte-for-byte in sync with that Swift
/// implementation (the whole point of moving this into the shader is that it's the exact same
/// pure function, just evaluated per-frame on the GPU instead of per-operation on the CPU).
inline float4 hueRampColor(float position) {
    float clamped = clamp(position, 0.0, 1.0);
    float3 rgb = hsvToRGB(clamped * 0.8, 0.8, 0.9);
    return float4(rgb, 1.0);
}

/// The GPU-facing counterpart to `MetalShapeColor.marker(forIndex:in:) ?? MetalShapeColor
/// .hueRamp(normalized)` (or `?? MetalShapeColor.neutral` for the two flat-color layouts) — a
/// marker of `1`/`2` overrides everything else; otherwise falls back to a hue-ramp of `value` or a
/// flat `neutralColor`, depending on `useHueRamp` (a per-renderer/`MetalShapeLayout` choice, see
/// `AnimationUniforms`'s own doc comment).
inline float4 resolveColorSource(
    float value, int marker, float useHueRamp, float4 primaryColor, float4 secondaryColor,
    float4 neutralColor
) {
    if (marker == 1) { return primaryColor; }
    if (marker == 2) { return secondaryColor; }
    return useHueRamp > 0.5 ? hueRampColor(value) : neutralColor;
}

/// Resolves an `AnimatedColorSource` to its current eased color — computes BOTH endpoints' colors
/// via `resolveColorSource` (identical math to what used to run once per touched operation on the
/// CPU, now run once per vertex per frame instead) and mixes them exactly like `resolveAnimated2`
/// mixes two positions. Mathematically identical interpolation math, just relocating WHERE each
/// endpoint's RGBA gets computed.
inline float4 resolveAnimatedColorSource(
    AnimatedColorSource source, float currentTime, float duration, float useHueRamp,
    float4 primaryColor, float4 secondaryColor, float4 neutralColor
) {
    float4 fromColor = resolveColorSource(
        source.fromValue, source.fromMarker, useHueRamp, primaryColor, secondaryColor, neutralColor);
    float4 toColor = resolveColorSource(
        source.toValue, source.toMarker, useHueRamp, primaryColor, secondaryColor, neutralColor);
    float t = clamp((currentTime - source.startTime) / duration, 0.0, 1.0);
    return mix(fromColor, toColor, easeInOutCubic(t));
}

/// `MetalBarRenderer`'s simpler counterpart to `resolveAnimatedColorSource` — no hue-ramp branch
/// at all, just a 3-way marker-vs-default pick, matching `MetalBarRenderer`'s own
/// `color(forIndex:in:)` (now retired in favor of this).
inline float4 resolveAnimatedMarkerColor(
    AnimatedMarkerColor source, float currentTime, float duration, float4 primaryColor,
    float4 secondaryColor, float4 neutralColor
) {
    float4 fromColor =
        source.fromMarker == 1 ? primaryColor : (source.fromMarker == 2 ? secondaryColor : neutralColor);
    float4 toColor =
        source.toMarker == 1 ? primaryColor : (source.toMarker == 2 ? secondaryColor : neutralColor);
    float t = clamp((currentTime - source.startTime) / duration, 0.0, 1.0);
    return mix(fromColor, toColor, easeInOutCubic(t));
}

#endif /* AnimatedField_h */
