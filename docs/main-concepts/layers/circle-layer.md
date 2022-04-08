---
id: circle-layer
sidebar_position: 6
---

# Circle Layer

You can add circle polygons to maps to users using `CircleLayerOptions()`.

``` dart
FlutterMap(
    options: MapOptions(),
    layers: [
        CircleLayerOptions(
            circles: [],
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

Unfinished
