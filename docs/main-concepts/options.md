---
id: options
sidebar_position: 2
---

# Options

The `options` property takes a `MapOptions()` object.

``` dart
FlutterMap(
    options: MapOptions(
        ...
    ),
);
```

This is where you'll configure most of your map viewport settings, but not settings that depend on a map layer.

None of the options are required, but the options property on the `FlutterMap()` is required. Note that not all of the options available are shown below.

## Center (`center:`)

Takes a `LatLng` object, specifying the latitude and longitude of the center of the map when it is first built. For example:  

``` dart
        center: LatLng(0.0, 0.0),
```

will put the map at '[Null Island](https://en.wikipedia.org/wiki/Null_Island)' on first build, where the Prime Meridian and Equator intersect at 0 deg Latitude and 0 deg Longitude.

Defaults to `LatLng(50.5, 30.51)`.

## Zoom (`zoom:`, `maxZoom:`)

Takes doubles, but should usually be set initially to integers (in double format).

For an explanation of zoom levels, see the [How Does It Work? page](/introduction/how-does-it-work#zoom).

`zoom:` specifies what the zoom level of the map should be when it is first built, defaulting to level 13. `maxZoom:` specifies what the maximum zoom level can be, and should depend on your use case and/or tile server. Minimum zoom is set to 1. For example:

``` dart
        zoom: 13.0,
        maxZoom: 19.0,
```

:::caution Maximum Zoom Level
Note that many tile servers will not support past a zoom level of 18. Open Street Maps supports up to level 19, and a small amount support up to level 22. Always specify the `maxZoom:` below the maximum zoom level of the server, to avoid your users seeing a void of grey tiles.
:::

## Boundaries (`maxBounds:`)

Takes a `LatLngBounds` to restrict the map view within a rectangular area. For example:

``` dart
        maxBounds: LatLngBounds(
            LatLng(-90, -180.0),
            LatLng(90.0, 180.0),
        ),
```

will ensure that the gray void around the world cannot appear on screen, at least in the default projection. This is recommended for many setups.

:::caution
Always specify your center within your boundaries to avoid errors. Boundaries will take preference over center.
:::

## Rotation (`rotation:`)

Takes a double specifying the bearing of the map when it is first built. For example:

``` dart
        center: 180.0,
```

will put the South of the map at the top of the device.

Defaults to 0(°).

## Interactivity Settings (`interactiveFlags:`)

Takes an integer represented by multiple bitwise operations, similar to using enumerables. For example:

``` dart
        InteractiveFlag.all & ~InteractiveFlag.rotate
```

allows/enables all interactions except for rotation (keeping the map at the heading specified by `rotation`).

The flags below are available:

| Flag             | Description                                                                  |
| :--------------- | :--------------------------------------------------------------------------- |
| `all`            | Enables all interactions                                                     |
| `none`           | Disables all interactions                                                    |
| `drag`           | Enables panning with one finger                                              |
| `pinchMove`      | Enables panning with two+ fingers                                            |
| `flingAnimation` | Enables fling animation when `drag`/`pinchMove` have enough 'Fling Velocity' |
| `pinchZoom`      | Enables zooming with a pinch gesture                                         |
| `doubleTapZoom`  | Enables zooming with a double tap (prevents `onTap` from firing)             |
| `rotate`         | Enables rotating the map with a twist gesture                                |

Use `&` for 'AND' logic and `~` for 'NOT' logic. Combining these two gates, as shown in the example, can lead to many combinations, each easy to put together.

Defaults to enabling all interactions (`all`).

## When Position Changed (`onPositionChanged:`)

Takes a function with two arguments.
Gets called whenever the map position is changed, even if it is not changed by the user. For example:

``` dart
        onPositionChanged: (MapPosition position, bool hasGesture) {
            // Your logic here. `hasGesture` dictates whether the change
            // was due to a user interaction or something else. `position` is
            // the new position of the map.
        }
```

## When Map Tapped (`onTap:`)

Takes a function with one argument.
Gets called whenever the the user taps/clicks/presses on the map. For example:

``` dart
        onTap: (LatLng location) {
            // Your logic here. `location` dictates the coordinate at which the user tapped.
        }
```
