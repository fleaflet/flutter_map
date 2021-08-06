---
id: options
sidebar_position: 2
---

# Options

The `options` property takes a `MapOptions()` object.

``` dart
import 'package:flutter_map/flutter_map.dart';

FlutterMap(
    options: MapOptions(
        ...
    ),
);
```

This is where you'll configure most of your map viewport settings, but not settings that depend on the map layer.

None of the options are required, but the options property on the FlutterMap().

## Center (`center:`)

Takes a `LatLng` object, specifying the latitude and longitude of the center of the map when it is first built.

For example:  

``` dart
        center: LatLng(0.0, 0.0),
```

will put the map at '[Null Island](https://en.wikipedia.org/wiki/Null_Island)' on first build, where the Prime Meridian and Equator intersect at 0 deg Latitude and 0 deg Longitude.

## Zoom (`zoom:`, `maxZoom:`)

Takes doubles, but should usually be set initially to integers (in double format).

For an explanation of zoom levels, see the [How Does It Work?](/introduction/how-does-it-work#zoom) page.

`zoom:` specifies what the zoom level of the map should be when it is first built. `maxZoom:` specifies what the maximum zoom level can be, and should depend on your use case and/or tile server. Minimum zoom is set to 1. For example:

``` dart
        zoom: 13.0,
        maxZoom: 19.0,
```

:::caution Maximum Zoom Level
Note that many tile servers will not support past a zoom level of 18. Open Street Maps supports up to level 19, and a small amount support up to level 22. Always specify the `maxZoom:` below the maximum zoom level of the server, to avoid your users seeing a void of grey tiles.
:::

## Boundaries (`bounds:`)

Takes a `LatLngBounds` object, which takes two `LatLng` objects specifying two corners (north-west, south-east) creating a square where the map view must remain within. For example:

``` dart
        center: LatLngBounds(
            LatLng(90, -90),
            LatLng(-90, 90),
        ),
```

:::caution
Always specify your center within your boundaries to avoid errors. Boundaries will take preference over center.
:::

## Rotation (rotation:)

Takes a double specifying the bearing of the map when it is first built.

For example:

``` dart
        center: 180.0,
```

will put the South of the map at the top of the device.

## When Position Changed (`onPositionChanged:`)

Takes a function with two arguments.
Gets called whenever the map position is changed, even if it is not changed by the user. For example:

``` dart
        onPositionChanged: (MapPosition position, bool hasGesture) {
            // Your logic here. 'hasGesture' dictates whether the change
            // was due to a user interaction or something else. 'position' is
            // the new position of the map.
        }
```
