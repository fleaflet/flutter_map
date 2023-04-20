# Polyline Layer

You can add lines to maps by making them out of individual coordinates using  `PolylineLayer` and `Polyline`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/PolylineLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/Polyline-class.html" %}

<figure><img src="../.gitbook/assets/ExamplePolyline.png" alt=""><figcaption><p>An example <code>Polyline</code></p></figcaption></figure>

```dart
PolylineLayer(
  polylines: [
    Polyline(
      points: [LatLng(30, 40), LatLng(20, 50), LatLng(25, 45),],
      color: Colors.blue,
    ),
  ],
),
```

{% hint style="warning" %}
Due to the nature of the Earth being a sphere, drawing lines perfectly requires large amounts of difficult maths that may not behave correctly when given certain edge-cases.

Avoid creating large polylines, or polylines that cross the edges of the map, as this may create undesired results.
{% endhint %}

{% hint style="warning" %}
Excessive use of polylines may create performance issues.

Consider using one of the methods below if you encounter jank:

* Keep `saveLayers` set to `false` (which is default). This will reduce rendering times, however it will also reduce the visual quality of the line at intersections.
* Enable `polylineCulling`. This will prevent the calculation and rendering of lines outside of the current viewport, however this may not work as expected in all situations.
* Simplify the polyline by reducing the number of points within it. This will reduce calculation times, however it will make the line less precise. This is recommended, for example, when zoomed further out. You may be able to use an external Flutter library for this, called ['simplify'](https://pub.dev/packages/simplify).
{% endhint %}

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
