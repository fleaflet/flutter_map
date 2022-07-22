# Polyline Layer

You can add lines to maps to display paths/ways made out of points to users using `PolylineLayerOptions()`.

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        PolylineLayerOptions(
            polylineCulling: false,
            polylines: [
                Polyline(
                  points: [LatLng(30, 40), LatLng(20, 50), LatLng(25, 45),],
                  color: Colors.blue,
                ),
            ],
        ),
    ],
),
```

{% hint style="warning" %}
Due to the nature of the Earth being a sphere, drawing lines perfectly requires large amounts of difficult maths that may not behave correctly when given certain edge-cases.

Avoid creating large polylines, or polylines that cross the edges of the map, as this may create undesired results.
{% endhint %}

{% hint style="warning" %}
Excessive use of polylines or use of complex polylines will create performance issues and lag/'jank' as the user interacts with the map. See [Performance Issues](../../faqs/late-initialization-errors.md#performance-issues) for more information.

By default, `saveLayers` is set to `false` to improve performance as much as possible. However, this will make the appearance a little less 'satisfying' - overlapping lines will make the intersection appear darker. Only set to `true` is appearance matters more than performance.

You may also use `polylineCulling` to help improve performance, although this may make the performance worse in some cases.

Another potential solution is simplifying the polyline, perhaps using an external Flutter library ['simplify'](https://pub.dev/packages/simplify).
{% endhint %}

## Polylines (`polylines:`)

As you can see `PolylineLayerOptions()` accepts list of `Polyline`s. Each determines the shape of a polyline by defining the `LatLng` of each point. 'flutter\_map' will then draw a line between each coordinate.

| Property            | Type            | Defaults            | Description                                                                                   |
| ------------------- | --------------- | ------------------- | --------------------------------------------------------------------------------------------- |
| `points`            | `List<LatLng>`  | required            | The coordinates of each point                                                                 |
| `strokeWidth`       | `double`        | `1.0`               | Width of the line                                                                             |
| `color`             | `Color`         | `Color(0xFF00FF00)` | Fill color                                                                                    |
| `borderStrokeWidth` | `double`        | `0.0`               | Width of the border of the line                                                               |
| `borderColor`       | `Color`         | `Color(0xFFFFFF00)` | Color of the border of the line                                                               |
| `gradientColors`    | `List<Color>?`  |                     | List of colors to make gradient fill instead of a solid fill                                  |
| `colorsStop`        | `List<double>?` |                     | List doubles representing the percentage of where to START each gradient color along the line |
| `isDotted`          | `bool`          | `false`             | Whether to make the line dotted/dashed instead of solid                                       |

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
