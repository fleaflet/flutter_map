---
id: polygon-layer
sidebar_position: 4
---

# Polygon Layer

You can add polygons to maps to display shapes made out of points to users using `PolygonLayerOptions()`.

``` dart
import 'package:flutter_map/flutter_map.dart';

FlutterMap(
    options: MapOptions(),
    layers: [
        PolygonLayerOptions(
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

## Polygons (`polygons:`)

As you can see `PolygonLayerOptions` accepts list of `Polygons` which determines the shape of the polygon by defining the `LatLng` of each corner. `flutter_map` will then draw a line between each coordinate, and fill it.

| Property             | Type                  | Defaults            | Description                                                |
| :------------------- | :-------------------- | :------------------ | :--------------------------------------------------------- |
| `points`             | `List<LatLng>`        | required            | The coordinates of each vertex                             |
| `holePointsList`     | `List<List<LatLng>>?` |                     | The coordinates of each vertex to 'cut-out' from the shape |
| `color`              | `Color`               | `Color(4278255360)` | Fill color                                                 |
| `borderStrokeWidth`  | `double`              | `0.0`               | Width of the border                                        |
| `borderColor`        | `Color`               | `Color(4294967040)` | Color of the border                                        |
| `disableHolesBorder` | `bool`                | `false`             | Whether to apply the border at the edge of 'cut-outs'      |
| `isDotted`           | `bool`                | `false`             | Whether to make the border dotted/dashed instead of solid  |

:::caution Inaccuracies
Due to the nature of the Earth being a sphere, drawing lines perfectly can be a challenge for the library. Avoid creating large polygons, or polygons that cross the edges of the map, as this will create undesired results.
:::
