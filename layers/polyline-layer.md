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

### Sticking With `PolylineLayer`

It is easiest to try to squeeze as much performance out of `Polyline`s as possible. However, this may not always be the best option.

Consider using both of the methods below:

* Split long lines into individual `Polyline`s at regular intervals, then enable `polylineCulling`, in order to prevent the calculation and rendering of `Polyline`s outside of the current viewport.
* Simplify the polyline by reducing the number of points within it, in order to reduce raster and calculation times. It is recommended to do this to varying degrees and resolutions based on the current zoom level. It may be possible to use an external Flutter library called ['simplify'](https://pub.dev/packages/simplify).

The first method will improve performance when zoomed in, as more `Polyline`s will be able to be culled, whilst the second method will improve performance when zoomed out, without impacting visuals (when done well).

### Using A Separate `TileLayer`

If using `PolylineLayer` as above still does not reach satisfactory performance, then the best option may be to render a custom tile set. For example, this may be necessary when attempting to draw a number of long-distance routes, or other widespread dataset.

We do not provide any detailed information on how to do this, although the general flow will likely look like the following:

1. Render all lines onto a square canvas, with the lines positioned correctly according to the CRS in use
2. Slice the canvas into a [slippy map](https://wiki.openstreetmap.org/wiki/Slippy\_map\_tilenames) tree
3. Repeat the above steps for every desired zoom level, increasing the resolution of the lines at higher zoom levels
4. Host the directory tree on a server, provide a way to download it to the user's filesystem, or add it to the assets of the app, then use the appropriate `TileProvider`: [tile-providers.md](tile-layer/tile-providers.md "mention")

## Routing/Navigation

Routing is out of scope for 'flutter\_map'. However, if you can get a list of coordinates from a 3rd party, then you can use polylines to show them!

A good open source option is [OSRM](http://project-osrm.org/), but if you want higher reliability and more functionality such as real-time based routing, you may want to try a commercial solution such as Mapbox or Google Maps.

## Converting Formats

You may have a polyline with 'Google Polyline Encoding' (which is a lossy compression algorithm to convert coordinates into a string and back). These are often returned from routing engines, for example. In this case, you'll need to decode the polyline to the correct format first, before you can use it in a `Polyline`'s `points` argument.

One way to accomplish this is to use another Flutter library called ['google\_polyline\_algorithm'](https://pub.dev/packages/google\_polyline\_algorithm), together with a custom method. You can use the code snippet below, which can just be pasted into a file and imported whenever needed:

```dart
import 'package:latlong2/latlong.dart';
export 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    show decodePolyline;

extension PolylineExt on List<List<num>> {
  List<LatLng> unpackPolyline() =>
      map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
}
```

You can then use the package and the above snippet by doing:

```dart
import '<code_snippet_path>'

decodePolyline('<encoded-polyline>').unpackPolyline(); // Returns `List<LatLng>` for a map polyline
```
