# flutter_map camera pitch — Design

## Summary

The current release of `flutter_map` draws every layer in a 2D coordinate system that it rotates about the viewport center, so it can't show a camera that looks at the ground at an angle. To add pitch, we replaced the 2D rotation with one 4 × 4 world-to-screen matrix in `MapCamera`, which uses MapLibre Native's camera model, and changed every conversion between screen positions and coordinates to use that matrix or its exact inverse. With one matrix, layers, markers, gestures and hit testing compute the same screen position for each coordinate. At pitch 0 the matrix is the current release's rotation, so the same code runs at every pitch, and screen positions on an unpitched map change only by floating-point error. `MapOptions.maxPitch` defaults to 0.

## Problem

`MapCamera` has `center`, `zoom` and `rotation`. Several parts of the code convert between screen positions and coordinates with the same 2D calculation: project the coordinate to pixels at the zoom, subtract the projected center point, and rotate about the viewport center (`rotatePoint`, the gesture code's `_rotateOffset`, `focusedZoomCenter`). `MobileLayerTransformer` draws each layer on a canvas the size of the rotated viewport's bounding box, centered in the viewport, and applies `Transform.rotate`. The marker layer is inside the same transformer and undoes the rotation for each marker.

With pitch, each of these is wrong. The visible ground is a trapezoid, not a rectangle. Ground near the top of the viewport is farther away and drawn smaller, so a screen pixel there shows more ground. A screen position has a coordinate only where its view ray meets the ground. #1273 (closed) drew each layer flat and then applied a fixed perspective entry, `setEntry(3, 1, -0.002)`. That entry was not derived from a camera, so nothing could invert it: `screenOffsetToLatLng`, gestures and markers each used a different approximation, and the flat layer did not fill the viewport.

We need pitch for mapigrade, which draws a MapLibre Native map under `flutter_map` layers, and both have to compute the same screen position for every coordinate. The work is 8 stacked PRs (#2304) that add about 10,300 lines, most of them tests. This document explains the camera model and the transforms that every PR depends on, so that reviewers know the model before they read PR 1 (#2283).

## Goals & Non-Goals

*Goals*

- One world-to-screen transform that every projection, layer, gesture and hit test uses.
- A coordinate is drawn within 0.1 px of where MapLibre Native draws it, at every pitch and rotation.
- At pitch 0, the same screen positions and events as the current release, up to floating-point error.
- Existing applications and plugins keep compiling, except classes that implement `MapController` (see Risks & Mitigations): we deprecate API that changes instead of removing it.
- At 60°, frame time within 10% of pitch 0 on a mid-range Android phone.
- Pitch up to 85°.

*Non-Goals*

- A sky, fog, terrain, or pitch above 85°.
- Markers that lie flat on the ground (MapLibre's `pitchAlignment: map`). An option for them would be additive, in a later change.
- Changing how ground layers paint. A layer that paints in projected pixels from `pixelOrigin` keeps working unchanged.

## Tenets

- Where MapLibre has made a choice (constants, gesture rules, limits), make the same choice, so that a map that combines both needs no conversion between them and users see familiar behavior.
- Use one code path at every pitch. Treat pitch 0 as the pitch at which the perspective has no effect.
- Prefer an exact inverse to an approximation.
- Prefer deprecating an API to breaking it.

## Proposal

### Camera model

The camera looks at the center point from distance `d`, at angle `pitch` from straight down:

```
        camera o
               |\
               | \   d = 0.5 · H / tan(fov / 2) = 1.5 H
         pitch |  \
               |   \
  -------------+----*------------------------>  toward the top of the viewport
                  center point     (ground)
```

We use MapLibre Native's constants: a vertical field of view of 36.87° (`DEFAULT_FOV`, 0.6435 rad), so `d` is 1.5 times the viewport height `H` (`getCameraToCenterDistance`). MapLibre chose the field of view arbitrarily; we use it because it works well in MapLibre, and because with it `flutter_map` and MapLibre compute the same screen positions. With this distance, the scale at the center point doesn't change with pitch, so **the zoom is the scale at the center point**: `minZoom`, `maxZoom` and zoom-dependent styling keep their meaning. Nearer ground is drawn larger and farther ground smaller; at 60°, the bottom edge of the viewport is drawn at 1.5 times and the top edge at 0.4 times the center scale.

### The world-to-screen transform

`MapCamera.pixelToScreenTransform` is this matrix:

```
screen = T(W/2, H/2) · P(d) · Rx(pitch) · Rz(rotation) · T(−project(center))
```

It applies to a point in projected pixels at the camera zoom, `crs.latLngToOffset(latLng, zoom)`: north up, with the zoom already applied. The steps apply right to left:

| Step | Matrix | Input space → output space | Effect |
|---|---|---|---|
| 1. Position | `T(−project(center))` | projected pixels → ground, relative to the center point | Moves the center point to the origin. This is the only place the position applies. |
| 2. Rotation | `Rz(rotation)` | ground, north up → ground, rotated | Rotates about the center point, in the ground plane (z = 0). |
| 3. Pitch | `Rx(pitch)` | ground → camera space | Rotates the ground plane about the horizontal screen axis through the center point. Ground above the center point on screen moves away from the camera and has depth z. |
| 4. Perspective | `P(d)`: entry (3, 2) = −1/d | camera space → screen, relative to the viewport center | Divides x and y by `w = 1 − z/d`. Ground at the center point has z = 0 and keeps scale 1. |
| 5. Viewport | `T(W/2, H/2)` | → screen | Moves the origin to the viewport's top-left corner. |

At pitch 0, steps 3 and 4 are the identity for ground points (z stays 0 and w stays 1), and the matrix is the current rotation about the viewport center. `MapCamera` leaves out the perspective entry at pitch 0, so that the matrix stays affine for the renderer. No code outside `MapCamera` applies position, rotation or pitch: every other caller uses this matrix or its inverse.

### Screen to ground: ray-casting

The inverse of a perspective matrix maps a screen position to a line, the view ray, not to a point. `screenOffsetToLatLng` therefore intersects the view ray with the ground plane, in closed form (`MapCamera._groundFromCenter`). For a screen offset `(x, y)` from the viewport center:

```
Y = y / (cos(pitch) + y · sin(pitch) / d)
X = x · (1 − Y · sin(pitch) / d)
ground offset from the center point = Rz(rotation) · (X, Y)
```

The denominator is 0 at the horizon, `y = −d / tan(pitch)`; above it the ray doesn't meet the ground. As in MapLibre Native, the visible ground ends at a **far limit**, where the view ray is 89.25° from straight down. The far limit is in the viewport only above a pitch of 70.8°. Above the far limit, ground layers draw nothing and `MapOptions.backgroundColor` shows. The new `maybeScreenOffsetToLatLng` returns null there; the existing, non-nullable `screenOffsetToLatLng` returns the coordinate on the far limit below the position.

Moving the center point only changes step 1, so the ground offset of a screen position doesn't depend on the center point or the zoom. This makes every gesture exact with one rule: cast the ray, change the camera, cast it again, and move the center point by the difference. Focal-point zoom, the rotate gesture, drag, fling, `MapController.move` with `offset` and `rotateAroundPoint` all use this rule, so the ground under the pointer stays under the pointer.

### Layers

The transformer a layer uses determines its kind, as in the current release, with no pitch flag:

- **Ground layers** (tiles, polygons, polylines, circles, overlay images) paint in projected pixels inside `GroundLayerTransformer`, as in the current release, and are drawn in perspective. `GroundLayerTransformer` is the new name of `MobileLayerTransformer`, which stays as a deprecated alias. The canvas is the bounding box of the visible ground, with its top-left corner at `pixelOrigin`. The transformer applies `pixelToScreenTransform · T(pixelOrigin)` and, when the map is pitched, clips the canvas to the visible ground, so that nothing behind the camera or beyond the far limit is drawn.
- **Billboard layers** (markers and polygon labels) use the new `BillboardLayerTransformer`, which fills the viewport with no transform. Each child is placed at `latLngToScreenOffset` of its point and drawn upright and unscaled.
- **Static layers** (attribution, scale bar) don't change.

`size`, `pixelOrigin` and `pixelBounds` keep their invariants, `pixelBounds.topLeft == pixelOrigin` and `pixelBounds.size == size`, and now describe the bounding box of the visible ground. At pitch 0, `size` and `pixelOrigin` are unchanged, and `pixelBounds` moves by less than 1 px, because it is no longer centered on the projected center point rounded down to whole pixels. A layer that paints at `project(p) − pixelOrigin` on a canvas of `size` therefore works pitched without changes. Hit testing needs no extra code: Flutter's `RenderTransform` inverts the 4 × 4 matrix.

### What the new system replaces

| Current release | With pitch |
|---|---|
| `latLngToScreenOffset`, `screenOffsetToLatLng`: 2D rotation via `rotatePoint` | The matrix, and ray-casting |
| `offsetToCrs`, `focusedZoomCenter`, drag and fling (`_rotateOffset`), controller offsets: 2D rotation | Ray-cast ground offsets |
| `size`, `pixelOrigin`, `pixelBounds`: the rotated viewport's bounding box, centered on the center point | The visible ground's bounding box, which at pitch 0 is the rotated viewport's bounding box |
| `MobileLayerTransformer`: centered `OverflowBox` and `Transform.rotate` | `GroundLayerTransformer`: top-left `OverflowBox`, the full matrix, and a clip when pitched |
| Markers inside `MobileLayerTransformer`, counter-rotated | `BillboardLayerTransformer`, at every pitch |
| Polygon labels: `canvas.rotate(−rotation)` in the polygon painter, each label after its own polygon unless `drawLabelsLast` is set | A second painter in `BillboardLayerTransformer`, after all polygons; `drawLabelsLast` is deprecated |
| `TileRangeCalculator`: one rectangle at one tile zoom | A tile cover of the visible ground, each tile at a zoom chosen from its size on screen |
| `CameraFit.bounds`: rectangular viewport | A short iteration on the projected bounds at the current pitch |

`MapCamera.rotatePoint` stays public, keeps its 2D meaning, and documents that it ignores pitch.

### Tiles and gestures

Far ground is drawn smaller, so the tile layer loads only the tiles that cover the visible ground, each at a zoom chosen from its size on screen and never finer than the current tile zoom: 36% to 58% fewer tile requests at 60° on a Pixel 4a. Two-finger vertical drag and Ctrl-drag pitch the map with MapLibre GL JS's rules, and use the existing `MapEventSource` values.

### Risks & Mitigations

- **Plugins that compute screen positions themselves** draw in the wrong place on a pitched map. This happens only in applications that raise `maxPitch`; the migration note tells plugin authors to use `latLngToScreenOffset` or `BillboardLayerTransformer`.
- **32-bit precision.** Flutter passes layer transforms to the engine as 32-bit floats, and `T(−project(center))` is about 10⁷ px at high zoom. `GroundLayerTransformer` multiplies the matrix by `T(pixelOrigin)` in 64-bit arithmetic first, so the large translations cancel.
- **Polygons behind the camera.** Flutter 3.27 fills nothing of a path that has a vertex behind the camera. The polygon painter clips each ring to the half-plane in front of the camera before filling it (#2292).
- **`MapController.pitch`** is a new interface member, so a class that implements `MapController` itself no longer compiles. A GitHub code search found almost no such classes. Open question: does this require a major release?

### Validation

- Unit tests compare the matrix and its inverse with positions that MapLibre Native computed, at pitch 0 to 60 and three rotations. In mapigrade, `flutter_map` overlays are within 0.066 px of the MapLibre map up to 85°.
- At pitch 0, geometry assertions recorded on the base commit pass. Golden images of markers match the current release; golden images of polygons differ only where a later polygon used to cover a label. Existing tests pass, with updated expectations where `pixelBounds` moved by less than 1 px and where camera fits changed.
- On a Pixel 4a (5G) at 60°, build time is 5% and raster time 9% higher than at pitch 0, with no frame over 16.7 ms.

## Rejected Alternatives

- **Draw flat, then apply a fixed perspective (#1273).** There is no camera to invert, so projections, gestures and markers each need their own approximation, which contradicts the first goal.
- **A per-layer pitch flag (`applyPitch`).** The transformer a layer uses already determines how the layer moves with the camera, and a flag can't detect a plugin that computes screen positions itself.
- **Counter-transform markers inside `MobileLayerTransformer`.** It needs the inverse perspective matrix for each marker, and near the far edge the two transforms don't cancel exactly.

## FAQ

**Why doesn't pitching change the zoom?** The zoom is the scale at the center point, and the camera distance of 1.5 H keeps that scale at every pitch. This is MapLibre's definition. Pitch rotates the camera about the center point, so the center point and the zoom stay fixed.

**Why is the layer canvas no longer centered on the center point?** At 60°, the visible ground extends 2.37 H beyond the center point but only 0.63 H before it. A centered canvas would be about 1.6 times larger, and would contain ground behind the camera.

**Why does the pitch stop at 85°?** Above 85°, the visible ground is a band a few pixels high. MapLibre GL JS also defaults to 85°.

**Where do I start reading the code?** `MapCamera._computePixelToScreenTransform` and `MapCamera._groundFromCenter` in `lib/src/map/camera/camera.dart`, then `ground_layer_transformer.dart` and `billboard_layer_transformer.dart` in `lib/src/layer/shared/`.

## References

- PR stack [#2304](https://github.com/fleaflet/flutter_map/pull/2304), target branch `pitch-support`:
  - [#2283](https://github.com/fleaflet/flutter_map/pull/2283) camera pitch: the matrix, ray-casting, the layer kinds
  - [#2282](https://github.com/fleaflet/flutter_map/pull/2282) pitch gestures
  - [#2285](https://github.com/fleaflet/flutter_map/pull/2285) camera fit and constraints
  - [#2287](https://github.com/fleaflet/flutter_map/pull/2287), [#2288](https://github.com/fleaflet/flutter_map/pull/2288), [#2289](https://github.com/fleaflet/flutter_map/pull/2289) tile level of detail
  - [#2291](https://github.com/fleaflet/flutter_map/pull/2291) pitch limit of 85° and the far limit
  - [#2292](https://github.com/fleaflet/flutter_map/pull/2292) polygons behind the camera
- Earlier attempt: [#1273](https://github.com/fleaflet/flutter_map/pull/1273)
- MapLibre Native `TransformState` (`DEFAULT_FOV`, `getCameraToCenterDistance`, `maxMercatorHorizonAngle`); MapLibre GL JS `src/ui/handler/two_fingers_touch.ts` and `mouse.ts`
