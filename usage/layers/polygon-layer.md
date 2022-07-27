# Polygon Layer

You can add polygons to maps to display shapes made out of points to users using `PolygonLayerOptions()`.

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        PolygonLayerOptions(
            polygonCulling: false,
            polygons: [
                Polygon(
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

Avoid creating large polygons, or polygons that cross the edges of the map, as this may create undesired results.
{% endhint %}

{% hint style="warning" %}
Excessive use of polygons or use of complex polygons will create performance issues and lag/'jank' as the user interacts with the map. See [performance-issues.md](../../faqs/performance-issues.md "mention") for more information.

To improve performance, try enabling `polygonCulling`. This will prevent the calculation and rendering of polygons outside of the current viewport, however this may not work as expected in all situations.
{% endhint %}

## Polygons (`polygons:`)

As you can see `PolygonLayerOptions()` accepts list of `Polygon`s. Each determines the shape of a polygon by defining the `LatLng` of each corner. 'flutter\_map' will then draw a line between each coordinate, and fill it.

| Property             | Type                    | Defaults                          | Description                                                |
| -------------------- | ----------------------- | --------------------------------- | ---------------------------------------------------------- |
| `points`             | `List<LatLng>`          | required                          | The coordinates of each vertex                             |
| `holePointsList`     | `List<List<LatLng>>?`   |                                   | The coordinates of each vertex to 'cut-out' from the shape |
| `color`              | `Color`                 | `Color(0xFF00FF00)`               | Fill color                                                 |
| `borderStrokeWidth`  | `double`                | `0.0`                             | Width of the border                                        |
| `borderColor`        | `Color`                 | `Color(0xFFFFFF00)`               | Color of the border                                        |
| `disableHolesBorder` | `bool`                  | `false`                           | Whether to apply the border at the edge of 'cut-outs'      |
| `isDotted`           | `bool`                  | `false`                           | Whether to make the border dotted/dashed instead of solid  |
| `label`              | `String?`               |                                   | Text to display as label in center of polygon              |
| `labelStyle`         | `TextStyle`             | `TextStyle()`                     | Custom styling to apply to the label                       |
| `labelPlacement`     | `PolygonLabelPlacement` | `PolygonLabelPlacement.polylabel` | Where to place the label in the polygon                    |

### More Polygon Operations

'flutter\_map' doesn't provide any public methods to manipulate polygons, as these would be deemed out of scope.

However, some useful methods can be found in libraries such as 'latlong2' and ['poly\_bool\_dart'](https://github.com/mohammedX6/poly\_bool\_dart). These can be applied to the input of `Polygon`'s `points` argument, and the map will do it's best to try to render them. However, more complex polygons - such as those with holes - may be painted inaccurately, and may therefore require manual adjustment (of `holePointsList`, for example).
