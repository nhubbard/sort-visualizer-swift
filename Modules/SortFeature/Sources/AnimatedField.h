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
    // See `MetalAnimatedField.swift`'s `MetalAnimationUniforms` doc comment: the array size and
    // value-range bounds a geometry formula needs but no single instance owns.
    float arrayCount;
    float valueRangeLowerBound;
    float valueRangeSpan;
    float scale;
    int geometryKind;
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

/// Layout-matched to `MetalAnimatedField.swift`'s `AnimatedFloat` — the scalar counterpart to
/// `resolveAnimated2` above, identical easing math for a single `Float` instead of a `float2`.
struct AnimatedFloat {
    float from;
    float to;
    float startTime;
};

inline float resolveAnimated(AnimatedFloat field, float currentTime, float duration) {
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

/// One layout's resolved geometry — the pair `shape_vertex` combines with `unitCorner` exactly
/// like `resolveAnimated2`'s old precomputed origin/size used to be combined.
struct ShapeGeometry {
    float2 origin;
    float2 size;
};

/// MSL port of `MetalShapeGeometry.swift`'s `resolveShapeGeometry` — MUST stay formula-for-formula
/// in sync with that Swift function (used there only as a test-seam CPU reference for
/// `MetalShapeRenderer.resolvedInstances(at:)`; this is the copy that actually runs, once per
/// vertex per frame, in production). `geometryKind` selects which of `MetalShapeGeometryKind`'s
/// cases applies for this draw call — fixed per `Layout` type, read from `uniforms.geometryKind`.
/// `slot`/`arrayIndex` are deliberately separate: every case but `pixelMesh` (case 3) uses
/// `arrayIndex`; `pixelMesh`'s grid-cell placement is a pure function of `slot` alone.
inline ShapeGeometry resolveShapeGeometry(
    int geometryKind, int slot, int arrayIndex, float value, float arrayCount,
    float valueRangeLowerBound, float valueRangeSpan, float2 viewportSize, float scale
) {
    float index = float(arrayIndex);
    float normalized = valueRangeSpan > 0.0
        ? (value - valueRangeLowerBound) / valueRangeSpan
        : 1.0;
    ShapeGeometry result;

    switch (geometryKind) {
        case 0: { // disparityBarGraph
            float barWidth = viewportSize.x / arrayCount;
            float disp = (1.0 + sin(M_PI_F * (value - index) / arrayCount)) * 0.5;
            float height = viewportSize.y * disp;
            result.origin = float2(index * barWidth, viewportSize.y - height);
            result.size = float2(barWidth, height);
            break;
        }
        case 1: { // rainbow
            float barWidth = viewportSize.x / arrayCount;
            float height = viewportSize.y * normalized;
            result.origin = float2(index * barWidth, viewportSize.y - height);
            result.size = float2(barWidth, height);
            break;
        }
        case 2: { // sineWave
            float columnWidth = viewportSize.x / arrayCount;
            float centerY = viewportSize.y / 2.0;
            float amplitude = viewportSize.y * 0.4;
            float y = centerY - amplitude * sin(2.0 * M_PI_F * normalized);
            float barThickness = 5.0 * scale;
            result.origin = float2(index * columnWidth, y - barThickness / 2.0);
            result.size = float2(columnWidth, barThickness);
            break;
        }
        case 3: { // pixelMesh
            float side = floor(sqrt(arrayCount) + 0.999999); // ceil, matching Swift's .rounded(.up)
            if (side <= 0.0) {
                result.origin = float2(0.0);
                result.size = float2(0.0);
                break;
            }
            float cellWidth = viewportSize.x / side;
            float cellHeight = viewportSize.y / side;
            int sideInt = int(side);
            float gridX = float(slot % sideInt);
            float gridY = float(slot / sideInt);
            result.origin = float2(gridX * cellWidth, gridY * cellHeight);
            result.size = float2(cellWidth, cellHeight);
            break;
        }
        case 4: { // scatterPlot
            float columnWidth = viewportSize.x / arrayCount;
            float dotDiameter = 6.0 * scale;
            float radius = dotDiameter / 2.0;
            float centerX = index * columnWidth + columnWidth / 2.0;
            float centerY = radius + (viewportSize.y - 2.0 * radius) * (1.0 - normalized);
            result.origin = float2(centerX - radius, centerY - radius);
            result.size = float2(dotDiameter, dotDiameter);
            break;
        }
        case 5: { // waveDots
            float columnWidth = viewportSize.x / arrayCount;
            float dotDiameter = 6.0 * scale;
            float radius = dotDiameter / 2.0;
            float verticalCenter = viewportSize.y / 2.0;
            float amplitude = viewportSize.y / 2.0 - radius;
            float centerX = index * columnWidth + columnWidth / 2.0;
            float centerY = verticalCenter + amplitude * sin(2.0 * M_PI_F * normalized);
            result.origin = float2(centerX - radius, centerY - radius);
            result.size = float2(dotDiameter, dotDiameter);
            break;
        }
        case 6: { // spiralDots
            float2 center = float2(viewportSize.x / 2.0, viewportSize.y / 2.0);
            float radius = min(viewportSize.x, viewportSize.y) / 2.5;
            float angle = M_PI_F * (2.0 * index / arrayCount - 0.5);
            float distance = normalized * radius;
            float dotDiameter = 6.0 * scale;
            float2 centerPoint = center + distance * float2(cos(angle), sin(angle));
            result.origin = centerPoint - dotDiameter / 2.0;
            result.size = float2(dotDiameter, dotDiameter);
            break;
        }
        case 7: { // disparityDots
            float2 center = float2(viewportSize.x / 2.0, viewportSize.y / 2.0);
            float radius = min(viewportSize.x, viewportSize.y) / 2.5;
            float dotDiameter = 6.0 * scale;
            float dotRadius = dotDiameter / 2.0;
            float disp = (1.0 + cos(M_PI_F * (value - index) / (arrayCount * 0.5))) * 0.5;
            float theta = M_PI_F * (2.0 * index / arrayCount - 0.5);
            float2 centerPoint = center + disp * radius * float2(cos(theta), sin(theta));
            result.origin = centerPoint - dotRadius;
            result.size = float2(dotDiameter, dotDiameter);
            break;
        }
        default: { // hoopStack (8)
            float centerX = viewportSize.x / 2.0;
            float baseRadiusX = min(viewportSize.y / 6.0, viewportSize.x / 2.0);
            float baseRadiusY = viewportSize.y / 18.0;
            float y = arrayCount > 1.0
                ? baseRadiusY + (viewportSize.y - 2.0 * baseRadiusY) * index / (arrayCount - 1.0)
                : viewportSize.y / 2.0;
            float scaleFactor = 0.2 + 0.8 * normalized;
            float radiusX = scaleFactor * baseRadiusX;
            float radiusY = scaleFactor * baseRadiusY;
            result.origin = float2(centerX - radiusX, y - radiusY);
            result.size = float2(2.0 * radiusX, 2.0 * radiusY);
            break;
        }
    }
    return result;
}

/// One wedge's 3 resolved points — the triangle-family counterpart to `ShapeGeometry`.
struct TriangleGeometry {
    float2 p0;
    float2 p1;
    float2 p2;
};

/// MSL port of `MetalShapeGeometry.swift`'s `resolveTriangleGeometry` — MUST stay formula-for-
/// formula in sync with that Swift function. `geometryKind` here is `MetalTriangleGeometryKind`'s
/// raw value (0=colorCircle, 1=disparityCircle, 2=spiral) — a SEPARATE namespace from
/// `resolveShapeGeometry`'s `geometryKind` parameter; see that Swift enum's own doc comment for
/// why the two safely share one uniform field. `p0` (every wedge's shared center) is computed
/// inline here, not read from any per-instance field — it never varies per-instance.
inline TriangleGeometry resolveTriangleGeometry(
    int geometryKind, int arrayIndex, float value, float previousValue, float arrayCount,
    float valueRangeLowerBound, float valueRangeSpan, float2 viewportSize
) {
    float index = float(arrayIndex);
    float previousIndex = fmod(index - 1.0 + arrayCount, arrayCount);
    float2 center = float2(viewportSize.x / 2.0, viewportSize.y / 2.0);

    TriangleGeometry result;
    result.p0 = center;

    switch (geometryKind) {
        case 0: { // colorCircle — position-only, radius fixed, angle depends only on index
            float radius = min(viewportSize.x, viewportSize.y) / 2.75;
            float thetaPrev = M_PI_F * (2.0 * previousIndex / arrayCount - 0.5);
            float thetaOwn = M_PI_F * (2.0 * index / arrayCount - 0.5);
            result.p1 = center + radius * float2(cos(thetaPrev), sin(thetaPrev));
            result.p2 = center + radius * float2(cos(thetaOwn), sin(thetaOwn));
            break;
        }
        case 1: { // disparityCircle
            float radius = min(viewportSize.x, viewportSize.y) / 2.5;
            float thetaPrev = M_PI_F * (2.0 * previousIndex / arrayCount - 0.5);
            float thetaOwn = M_PI_F * (2.0 * index / arrayCount - 0.5);
            float dispPrev = (1.0 + cos(M_PI_F * (previousValue - previousIndex) / (arrayCount * 0.5))) * 0.5;
            float dispOwn = (1.0 + cos(M_PI_F * (value - index) / (arrayCount * 0.5))) * 0.5;
            result.p1 = center + dispPrev * radius * float2(cos(thetaPrev), sin(thetaPrev));
            result.p2 = center + dispOwn * radius * float2(cos(thetaOwn), sin(thetaOwn));
            break;
        }
        default: { // spiral (2)
            float radius = min(viewportSize.x, viewportSize.y) / 2.5;
            float thetaPrev = M_PI_F * (2.0 * previousIndex / arrayCount - 0.5);
            float thetaOwn = M_PI_F * (2.0 * index / arrayCount - 0.5);
            float normalizedPrev = valueRangeSpan > 0.0
                ? (previousValue - valueRangeLowerBound) / valueRangeSpan : 1.0;
            float normalizedOwn = valueRangeSpan > 0.0
                ? (value - valueRangeLowerBound) / valueRangeSpan : 1.0;
            float multPrev = 1.0 - (1.0 - normalizedPrev) * (1.0 - normalizedPrev);
            float multOwn = 1.0 - (1.0 - normalizedOwn) * (1.0 - normalizedOwn);
            result.p1 = center + multPrev * radius * float2(cos(thetaPrev), sin(thetaPrev));
            result.p2 = center + multOwn * radius * float2(cos(thetaOwn), sin(thetaOwn));
            break;
        }
    }
    return result;
}

/// One chord's resolved endpoints — `MetalDisparityChordsRenderer`'s own geometry.
struct ChordGeometry {
    float2 start;
    float2 end;
};

/// MSL port of `MetalShapeGeometry.swift`'s `resolveChordGeometry` — the only line-based renderer,
/// so `line_vertex` always applies this one formula unconditionally, no `geometryKind` selector
/// needed. `index` is always `instanceID` directly — see that Swift function's own doc comment.
inline ChordGeometry resolveChordGeometry(
    int index, float value, float arrayCount, float2 viewportSize
) {
    float2 center = float2(viewportSize.x / 2.0, viewportSize.y / 2.0);
    float radius = min(viewportSize.x, viewportSize.y) / 2.5;
    float fromAngle = M_PI_F * (2.0 * float(index) / arrayCount - 0.5);
    float toAngle = M_PI_F * (2.0 * value / arrayCount - 0.5);
    ChordGeometry result;
    result.start = center + radius * float2(cos(fromAngle), sin(fromAngle));
    result.end = center + radius * float2(cos(toAngle), sin(toAngle));
    return result;
}

#endif /* AnimatedField_h */
