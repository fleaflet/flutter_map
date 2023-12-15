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

## Performance Recommendations

Excessive use of polylines may create performance issues. There are two options to attempt to improve performance.

{% hint style="success" %}
We're working on improvements right now to make your app even more buttery smooth! Stay up to date with the latest performance improvements by joining our Discord server.
{% endhint %}

### Sticking With `PolylineLayer`

It is easiest to try to squeeze as much performance out of `Polyline`s as possible. However, this may not always be the best option.

Consider using both of the methods below:

* Split long lines into individual `Polyline`s at regular intervals, then enable `polylineCulling`, in order to prevent the calculation and rendering of `Polyline`s outside of the current viewport.
* Simplify the polyline by reducing the number of points within it, in order to reduce raster and calculation times. It is recommended to do this to varying degrees and resolutions based on the current zoom level. It may be possible to use an external Flutter library called [simplify](https://pub.dev/packages/simplify).

The first method will improve performance when zoomed in, as more `Polyline`s will be able to be culled, whilst the second method will improve performance when zoomed out, without impacting visuals (when done well).

### Using A Separate `TileLayer`

If using `PolylineLayer` as above still does not reach satisfactory performance, then the best option may be to render a custom tile set. For example, this may be necessary when attempting to draw a number of long-distance routes, or other widespread dataset.

{% hint style="info" %}
We're unable to provide support with this method, and this may become outdated.
{% endhint %}

The first step is to render the desired lines into a tileset with a transparent background - [tippecanoe](https://github.com/mapbox/tippecanoe) is commonly used to do this, and generates vector-format MBTiles.

If you have raster tiles, you're all set to serve as normal. However, and much more likely, if you have raster tiles, you're all set to serve as normal/as you choose. More commonly though, you'll have vector tiles at this step, as with 'tippecanoe', so you'll need to do one of the following things:

* Try to convert it to raster tiles all in one shot, then use a tool like [mbtilesToPngs](https://github.com/alfanhui/mbtilesToPngs) to extract the raster .mbtiles into a slippy map tree
* Give the MBTiles/vector tiles to the vector map plugin
* Serve the tiles via something like [tileserver-gl](https://github.com/maptiler/tileserver-gl), which provides an on-the-fly rasterizer

To provide the tiles to the users within flutter\_map, see [tile-providers.md](tile-layer/tile-providers.md "mention").

## Interactivity

It is possible to detect hits (for example, hovers, taps, and long-presses) that occur over polylines.

### Hit Notifier

Hit detection is achieved by passing a `ValueNotifier` to the `hitNotifier` parameter. The layer internals will then notify the notifier with a `PolylineHit` result when a new hit is detected (and notify `null` when a hit is not detected).

{% code title="hit_notifier.dart" %}
```dart
final PolylineHitNotifier hitNotifier = ValueNotifier(null);

// Inside the map build...
PolylineLayer(
  hitNotifier: hitNotifier,
  polylines: [],
);
```
{% endcode %}

If all that is required is to get notified when a new hit event occurs (including hovers), it is then possible to listen to the notifier directly with `addListener` - don't forget to remove the listener once you no longer need it!

### Gesture Detection

However, usually events will need to be 'filtered' to only detect taps or long presses, for example. In this case, wrap the layer with other hit detection widgets as you would do normally to detect taps.

{% hint style="info" %}
We don't provide direct callbacks for gesture handling, in order to maximize flexibility.
{% endhint %}

{% code title="tappable_polyline.dart" %}
```dart
// Inside the map build...
MouseRegion(
  hitTestBehavior: HitTestBehavior.deferToChild,
  cursor: SystemMouseCursors.click, // Use a special cursor to indicate interactivity
  child: GestureDetector(
    // Detect gesture events as normal, including long press, etc.
    onTap: () {
      if (hitHandler.value == null) return;
      for (final line in hitHandler.value!.lines) {}
    }, 
    child: PolylineLayer(
      hitNotifier: hitNotifier,
    ),
  ),
),
```
{% endcode %}

To get the lines that were hit within the handlers of other hit detection widgets, use `hitHandler.value?.lines`. This contains all the hit lines in order from visually on top - bottom.

You may also get the hit coordinate (which may not lie on any polyline), with `.point`.

### Attaching Metadata

There is no direct facility to attach free-form data to a `Polyline` in order to later identify them or use the data when hit handling.

However, we recommend creating a `Map<Polyline, Metadata>` where `Metadata` is any type. It is best to do this outside the `build` method unless either the key or value is dynamic/variable, to improve performance.

{% code title="metadata.dart" %}
```dart
final polylines = <Polyline, Metadata>{};

// Inside the map build...
PolylineLayer<String>(
  hitNotifier: hitNotifier,
  polylines: polylines.keys,
);

// When handling gestures...
polylines[hitNotifier.value?.lines[x]] is Metadata;
```
{% endcode %}

## Routing/Navigation

Routing is out of scope for 'flutter\_map'. However, if you can get a list of coordinates from a 3rd party, then you can use polylines to show them!

Good open source options that can be self-hosted include [OSRM](http://project-osrm.org/) (which includes a public demo server) and [Valhalla](https://github.com/valhalla/valhalla). You can also use a commercial solution such as Mapbox or Google Maps - these can often give more accurate/preferable results because they can use their traffic data when routing.

## Converting Formats

You may have a polyline with 'Google Polyline Encoding' (which is a lossy compression algorithm to convert coordinates into a string and back). These are often returned from routing engines, for example. In this case, you'll need to decode the polyline to the correct format first, before you can use it in a `Polyline`'s `points` argument.

One way to accomplish this is to use another Flutter library called ['google\_polyline\_algorithm'](https://pub.dev/packages/google\_polyline\_algorithm), together with a custom method. You can use the code snippet below, which can just be pasted into a file and imported whenever needed:

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
