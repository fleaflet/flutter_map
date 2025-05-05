# Polyline Layer

You can add lines to maps by making them out of individual coordinates using `PolylineLayer` and `Polyline`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/PolylineLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/Polyline-class.html" %}

<figure><img src="../.gitbook/assets/ExamplePolyline.png" alt=""><figcaption><p>An example <code>Polyline</code></p></figcaption></figure>

```dart
PolylineLayer(
  polylines: [
    Polyline(
      points: [LatLng(30, 40), LatLng(20, 50), LatLng(25, 45)],
      color: Colors.blue,
    ),
  ],
),
```

## Pattern

`Polyline`s support a `solid`, `dotted`, and `dashed` style, through a `StrokePattern`passed as an argument to`Polyline.pattern`. These are flexible, and spacing and sizing may be customized.

`dotted` and `dashed` patterns should 'fit' the `Polyline` they are applied to, otherwise the final point in that line may not be visually clear. The fit can be adjusted when defining the pattern through the `PatternFit` enum.

<figure><img src="../.gitbook/assets/PatternFit.png" alt="" width="375"><figcaption><p>Illustration of the 5 types of <code>PatternFit</code> applied to a <code>dashed</code> <code>Polyline</code><br>From left to right: <code>none</code>, <code>appendDot</code>, <code>extendFinalDash</code>, <code>scaleUp</code> (default), <code>scaleDown</code></p></figcaption></figure>

## Interactivity

`PolylineLayer`s and `Polyline`s support hit detection and interactivity.

{% content-ref url="layer-interactivity/" %}
[layer-interactivity](layer-interactivity/)
{% endcontent-ref %}

{% hint style="info" %}
If any polylines are very thin, it is recommended for accessibility reasons to increase the size of the 'hitbox' (the area where a hit is detected on a polyline) to larger than the line itself in order to make it easier to tap/interact with the polyline.

The `minimumHitbox` argument adjusts the minimum size of the hitbox - the size of the hitbox will usually be the entire visual area/thickness of the polyline (and border), but will be no less than this value. It defaults to 10.
{% endhint %}

## Multi-Worlds

The `PolylineLayer` paints its `Polyline`s across all visible worlds by default. This can be changed.

{% content-ref url="../usage/basics/unbounded-horizontal-scrolling.md" %}
[unbounded-horizontal-scrolling.md](../usage/basics/unbounded-horizontal-scrolling.md)
{% endcontent-ref %}

## Performance Optimizations

{% hint style="success" %}
The example application includes a stress test which generates a `Polyline` with 200,000 points.
{% endhint %}

### Culling

To improve performance, line segments that are entirely offscreen are effectively removed - they are not processed or painted/rendered. This is enabled by default and disabling it is not recommended.

{% hint style="warning" %}
Polylines that are particularly wide (due to their `strokeWidth`/`borderStrokeWidth` may be improperly culled if using the default configuration. This is because culling decisions are made on the 'infinitely thin line' joining the `points`, not the visible line, for performance reasons.

Therefore, the `cullingMargin` parameter is provided, which effectively increases the distance a segement needs to be from the viewport edges before it can be culled. Increase this value from its default if line segements are visibly disappearing unexpectedly.
{% endhint %}

{% hint style="warning" %}
Culling cannot be applied to polylines with a gradient fill, as this would cause inconsistent gradients.

These will be automatically internally excluded from culling: it is not necessary to disable it layer-wide - unless all polylines have gradient fills, in which case that may yield better performance.

Avoid using these if performance is of importance. Instead, try using multiple polylines with coarser color differences.
{% endhint %}

### Simplification

To improve performance, polylines are 'simplified' before being culled and painted/rendered. The well-known [Ramer–Douglas–Peucker algorithm](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) is used to perform this, and is enabled by default.

> Simplification algorithms reduce the number of points in each line by removing unnecessary points that are 'too close' to other points which create tiny line segements invisible to the eye. This reduces the number of draw calls and strain on the raster/render thread. This should have minimal negative visual impact (high quality), but should drastically improve performance.
>
> For this reason, polylines can be more simplified at lower zoom levels (more zoomed out) and less simplified at higher zoom levels (more zoomed in), where the effect of culling on performance improves and trades-off. This is done by scaling the `simplificationTolerance` parameter (see below) automatically internally based on the zoom level.

To adjust the quality and performance of the simplification, the maximum distance between removable points can be adjusted through the `simplificationTolerance` parameter. Increasing this value (from its default of 0.4) results in a more jagged, less accurate (lower quality) simplification, with improved performance; and vice versa. Many applications use a value in the range 0 - 1.

To disable simplification, set `simplificationTolerance` to 0.&#x20;

{% hint style="warning" %}
The simplification step must run before culling, to avoid the polyline appearing to change when interacting with the map (due to the first and last points of the polyline changing, influencing the rest of the simplified points).

Therefore, reducing/disabling simplification will yield better performance on complex polylines that are out of the camera view (and therefore culled without requiring the potentially expensive simplification). However, using simplification will likely improve performance overall - it does this by reducing the load on the raster thread and slightly increasing the load on the UI/build/widget thread.
{% endhint %}

{% hint style="warning" %}
On layers with (many) only 'short' polylines (those with few points), disabling simplification may yield better performance.
{% endhint %}

## Routing/Navigation

Routing is out of scope for 'flutter\_map'. However, if you can get a list of coordinates from a 3rd party, then you can use polylines to show them!

Good open source options that can be self-hosted include [OSRM](http://project-osrm.org/) (which includes a public demo server) and [Valhalla](https://github.com/valhalla/valhalla). You can also use a commercial solution such as Mapbox or Google Maps - these can often give more accurate/preferable results because they can use their traffic data when routing.

### Converting Formats

You may have a polyline with 'Google Polyline Encoding' (which is a lossy compression algorithm to convert coordinates into a string and back). These are often returned from routing engines, for example. In this case, you'll need to decode the polyline to the correct format first, before you can use it in a `Polyline`'s `points` argument.

One way to accomplish this is to use another Flutter library called ['google\_polyline\_algorithm'](https://pub.dev/packages/google_polyline_algorithm), together with a custom method. You can use the code snippet below, which can just be pasted into a file and imported whenever needed:

{% code title="unpack_polyline.dart" %}
```dart
import 'package:latlong2/latlong.dart';
export 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    show decodePolyline;

extension PolylineExt on List<List<num>> {
  List<LatLng> unpackPolyline() =>
      map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
}
```
{% endcode %}

You can then use the package and the above snippet by doing:

```dart
import 'unpack_polyline.dart';

decodePolyline('<encoded-polyline>').unpackPolyline(); // Returns `List<LatLng>` for a map polyline
```
