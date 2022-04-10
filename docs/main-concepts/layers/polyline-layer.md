---
id: polyline-layer
sidebar_position: 5
---

# Polyline Layer

You can add lines to maps to display paths/ways made out of points to users using `PolylineLayerOptions()`.

``` dart
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

:::caution Inaccuracies
Due to the nature of the Earth being a sphere, drawing lines perfectly requires large amounts of difficult maths that may not behave correctly when given certain edge-cases. Avoid creating large polylines, or polylines that cross the edges of the map, as this may create undesired results.
:::

:::caution Performance Issues
Excessive use of polylines or use of complex polylines will create performance issues and lag/'jank' as the user interacts with the map. See [Performance Issues](/examples-and-errors/common-errors#performance-issues) for more information.

To improve performance, try enabling `polylineCulling`. This should remove polylines that are out of sight, but should only be used when necessary as enabling this can further reduce performance when used unnecessarily.
:::

## Polylines (`polylines:`)

As you can see `PolylineLayerOptions()` accepts list of `Polyline`s. Each determines the shape of a polyline by defining the `LatLng` of each point. `flutter_map` will then draw a line between each coordinate.

| Property            | Type            | Defaults            | Description                                                                                   |
| :------------------ | :-------------- | :------------------ | :-------------------------------------------------------------------------------------------- |
| `points`            | `List<LatLng>`  | required            | The coordinates of each point                                                                 |
| `strokeWidth`       | `double`        | `1.0`               | Width of the line                                                                             |
| `color`             | `Color`         | `Color(0xFF00FF00)` | Fill color                                                                                    |
| `borderStrokeWidth` | `double`        | `0.0`               | Width of the border of the line                                                               |
| `borderColor`       | `Color`         | `Color(0xFFFFFF00)` | Color of the border of the line                                                               |
| `gradientColors`    | `List<Color>?`  |                     | List of colors to make gradient fill instead of a solid fill                                  |
| `colorsStop`        | `List<double>?` |                     | List doubles representing the percentage of where to START each gradient color along the line |
| `isDotted`          | `bool`          | `false`             | Whether to make the line dotted/dashed instead of solid                                       |

## Converting Formats

You may have a 'Google encoded' polyline, from a routing engine for example, that you want to paint as a polyline, in which case, you'll need to decode the polyline into a list of `LatLng`s to give to the `points` property.

The easiest way to do this is use an unrelated external Flutter library called [flutter_polyline_points](https://pub.dev/packages/flutter_polyline_points), and the built-in `.map()` function. Install and import the package, `latlong2` & `flutter_map` into a new file in your project, and copy/paste the code below:

```dart
extension EncodedPolyline on String {
    List<LatLng> decodePolyline() =>
        PolylinePoints()
        .decodePolyline(this)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
}
```

You can now export/import this file wherever needed and convert an encoded polyline `String` to `List<LatLng>` whenever you need, just by calling `.decodePolyline()` on the `String`.
