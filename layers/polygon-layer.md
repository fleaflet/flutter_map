# Polygon Layer

You can add areas/shapes to maps by making them out of individual coordinates using `PolygonLayer` and `Polygon`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/PolygonLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/Polygon-class.html" %}

<figure><img src="../.gitbook/assets/ExamplePolygon.png" alt=""><figcaption><p>An example <code>Polygon</code></p></figcaption></figure>

```dart
PolygonLayer(
  polygons: [
    Polygon(
      points: [LatLng(30, 40), LatLng(20, 50), LatLng(25, 45)],
      color: Colors.blue,
      isFilled: true,
    ),
  ],
),
```

## Interactivity

`PolygonLayer`s and `Polygons`s support hit detection and interactivity.

{% content-ref url="layer-interactivity/" %}
[layer-interactivity](layer-interactivity/)
{% endcontent-ref %}

## Performance Optimizations

flutter\_map includes many performance optimizations built in, especially as of v7. Some are enabled by default, but may be only 'weakly' applied, and others must be enabled manually. There are also some other actions that can be taken externally to improve performance

The following list is ordered from least 'intrusive'/extreme, to most intrusive. Remember to consider the potential risks of enabling an optimization before doing so.

{% hint style="success" %}
The example application includes a stress test which loads multiple `Polygon`s from a GeoJson file, with a total of 138,000 points.
{% endhint %}

***

<details>

<summary>Culling <em>(enabled by default)</em></summary>

To improve performance, polygons that are entirely offscreen are effectively removed - they are not processed or painted/rendered. This is enabled by default, and may be disabled using the `polygonCulling` parameter, although this is not recommended.

</details>

***

<details>

<summary>Batching <em>(enabled by default, but improvable with effort)</em></summary>

To improve performance, polygons that are similar in appearance, and borders that are similar in appearance, are drawn to the underlying canvas in batches, to reduce the number of draw calls. This cannot be disabled.

To further improve performance, consider defining all `Polygon` `points` in a clockwise order, and place similar appearance `Polygon`s adjacent to each other in the `polygons` list (where elevation does not matter).

</details>

{% hint style="warning" %}
Overlapping colors that are not completely opaque will not recieve the 'darkening'/layering effect - the overlapping area will just be the single colour.&#x20;
{% endhint %}

***

<details>

<summary>Simplification <em>(enabled by default, adjustable)</em></summary>

To improve performance, polygon outlines (`points`) are 'simplified' before the polygons are culled and painted/rendered. The well-known [Ramer–Douglas–Peucker algorithm](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker\_algorithm) is used to perform this, and is enabled by default.

To adjust the quality and performance of the simplification, the maximum distance between removable points can be adjusted through the `simplificationTolerance` parameter. Increasing this value (from its default of 0.5) results in a more jagged, less accurate (lower quality) simplification, with improved performance; and vice versa. Many applications use a value in the range 1 - 1.5. To disable simplification, set `simplificationTolerance` to 0.&#x20;

***

Simplification algorithms reduce the number of points in each line by removing unnecessary points that are 'too close' to other points which create tiny line segements invisible to the eye. This reduces the number of draw calls and strain on the raster/render thread. This should have minimal negative visual impact (high quality), but should drastically improve performance.

For this reason, polygons can be more simplified at lower zoom levels (more zoomed out) and less simplified at higher zoom levels (more zoomed in), where the effect of culling on performance improves and trades-off. This is done by scaling the `simplificationTolerance` parameter (see below) automatically internally based on the zoom level.

</details>

{% hint style="warning" %}
On layers with (many) only small polygons (those with few points), disabling simplification may yield better performance.
{% endhint %}

{% hint style="warning" %}
Polygons may overlap after simplification when they did not before, and vice versa.
{% endhint %}

***

<details>

<summary>Performant Rendering, with <code>drawVertices</code> <em>(disabled by default)</em></summary>

Polygons (and similar other features) are usually drawn directly onto a `Canvas`, using built-in methods such as `drawPolygon` and `drawLine`. However, these can be relatively slow, and will slow the raster thread when used at a large scale.

Therefore, to improve performance, it's possible to optionally set the `useAltRendering` flag on the `PolygonLayer`. This will use an alternative, specialised, rendering pathway, which _may_ lead to an overall performance improvement, particularly at a large scale.

***

There's two main steps to this alternative rendering algorithm:

1. Cut each `Polygon` into multiple triangles through a process known as [triangulation](https://en.wikipedia.org/wiki/Polygon\_triangulation). flutter\_map uses an earcutting algorithm through [dart\_earcut](https://pub.dev/packages/dart\_earcut) (a port of an algorithm initially developed at Mapbox intended for super-large scale triangulation).
2. Draw each triangle onto the canvas via the lower-level, faster [`drawVertices`](https://api.flutter.dev/flutter/dart-ui/Canvas/drawVertices.html) method. Borders are then drawn as normal.

</details>

{% hint style="warning" %}
Self-intersecting (complex) `Polygon`s are not supported by the triangulation algorithm, and could cause errors.

The Shamos-Hoey algorithm could be used to automatically detect self-intersections, and set the feature-level flag correspondingly. If doing this, remember that the simplification step (which runs prior to this) could either add or remove a self-intersection.

Holes are supported.
{% endhint %}

{% hint style="warning" %}
This pathway may be slower than the standard pathway, especially when used on a large scale but with simplification disabled, or used on an especially small scale.

It is intended for use when prior profiling indicates more performance is required after other methods are already in use.
{% endhint %}

{% hint style="warning" %}
Rarely, some visible artefacts may be introduced by the triangulation algorithm.
{% endhint %}

***

<details>

<summary>Use No/Thin Borders or Cheaper <code>StrokeCap</code>s/<code>StrokeJoin</code>s <em>(external)</em></summary>

To further improve performance, consider using no border, or a hairline 1px border (remembering to consider the difference between device and logical pixels). Alternatively, consider using `StrokeCap.butt`/`StrokeCap.square` & `StrokeJoin.miter`/`StrokeJoin.bevel`.\
These are much cheaper for the rendering engine (particularly Skia), as it does not have to perform as many calculations.&#x20;

</details>

## Polygon Manipulation

'flutter\_map' doesn't provide any public methods to manipulate polygons, as these would be deemed out of scope.

However, some useful methods can be found in libraries such as 'latlong2' and ['poly\_bool\_dart'](https://github.com/mohammedX6/poly\_bool\_dart). These can be applied to the input of `Polygon`'s `points` argument, and the map will do it's best to try to render them. However, more complex polygons - such as those with holes - may be painted inaccurately, and may therefore require manual adjustment (of `holePointsList`, for example).
