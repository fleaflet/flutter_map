---
id: marker-layer
sidebar_position: 3
---

# Marker Layer

You can add markers to maps to display specific points to users using `MarkerLayerOptions()`.

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        MarkerLayerOptions(
            markers: [
                Marker(
                  point: LatLng(30, 40),
                  width: 80,
                  height: 80,
                  builder: (context) => FlutterLogo(),
                ),
            ],
        ),
    ],
),
```

## Markers (`markers`)

As you can see `MarkerLayerOptions` accepts list of Markers which determines render widget, position and transformation details like size and rotation.

| Property          | Type                 | Description                                                    |
| :---------------- | :------------------- | :------------------------------------------------------------- |
| `point`           | `LatLng`             | Marker position on map                                         |
| `builder`         | `WidgetBuilder`      | Builder used to render market                                  |
| `width`           | `double`             | Marker width                                                   |
| `height`          | `double`             | Marker height                                                  |
| `rotate`          | `bool?`              | If true marker will be counter rotated to the map rotation     |
| `rotateOrigin`    | `Offset?`            | The origin of the marker in which to apply the matrix.         |
| `rotateAlignment` | `AlignmentGeometry?` | The alignment of the origin, relative to the size of the box   |
| `anchorPos`       | `AnchorPos?`         | Point of the marker which will correspond to marker's location |
