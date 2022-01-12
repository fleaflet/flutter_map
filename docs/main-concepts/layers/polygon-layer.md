---
id: polygon-layer
sidebar_position: 5
---

# Polygon Layer

You can add polygons to maps to display shapes made out of points to users using `PolygonLayerOptions()`.

``` dart
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

:::caution Inaccuracies
Due to the nature of the Earth being a sphere, drawing lines perfectly requires large amounts of difficult maths that may not behave correctly when given certain edge-cases. Avoid creating large polygons, or polygons that cross the edges of the map, as this may create undesired results.
:::
:::caution Performance Issues
Excessive use of polygons, use of `isDotted: true`, or use of complex polygons, etc., will create performance issues and lag/'jank' as the user interacts with the map.

To improve performance, enable `polygonCulling`. This should remove polygons that are out of sight, but should only be used when necessary as enabling this can further reduce performance when used unnecessarily.
:::

## Polygons (`polygons:`)

As you can see `PolygonLayerOptions()` accepts list of `Polygon`s. Each determines the shape of a polygon by defining the `LatLng` of each corner. `flutter_map` will then draw a line between each coordinate, and fill it.

| Property             | Type                  | Defaults            | Description                                                |
| :------------------- | :-------------------- | :------------------ | :--------------------------------------------------------- |
| `points`             | `List<LatLng>`        | required            | The coordinates of each vertex                             |
| `holePointsList`     | `List<List<LatLng>>?` |                     | The coordinates of each vertex to 'cut-out' from the shape |
| `color`              | `Color`               | `Color(0xFF00FF00)` | Fill color                                                 |
| `borderStrokeWidth`  | `double`              | `0.0`               | Width of the border                                        |
| `borderColor`        | `Color`               | `Color(0xFFFFFF00)` | Color of the border                                        |
| `disableHolesBorder` | `bool`                | `false`             | Whether to apply the border at the edge of 'cut-outs'      |
| `isDotted`           | `bool`                | `false`             | Whether to make the border dotted/dashed instead of solid  |