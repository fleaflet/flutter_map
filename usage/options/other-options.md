---
description: Visit the Full API Reference for the full list of available options
---

# Other Options

## Interactivity Settings (`interactiveFlags`)

Takes an integer bitfield, which can be treated similar to enumerables. For example:

```dart
        InteractiveFlag.all & ~InteractiveFlag.rotate
```

allows/enables all interactions except for rotation (keeping the map at the heading specified by `rotation`).

The flags below are available:

| Flag             | Description                                                                  |
| ---------------- | ---------------------------------------------------------------------------- |
| `all`            | Enables all interactions                                                     |
| `none`           | Disables all interactions                                                    |
| `drag`           | Enables panning with one finger                                              |
| `pinchMove`      | Enables panning with two or more fingers                                     |
| `flingAnimation` | Enables fling animation when `drag`/`pinchMove` have enough 'Fling Velocity' |
| `pinchZoom`      | Enables zooming with a pinch gesture                                         |
| `doubleTapZoom`  | Enables zooming with a double tap (prevents `onTap` from firing)             |
| `rotate`         | Enables rotating the map with a twist gesture                                |

Use `&` for 'AND' logic and `~` for 'NOT' logic. Combining these two gates, as shown in the example, can lead to many combinations, each easy to put together.

Defaults to enabling all interactions (`all`).

## Scroll Wheel Settings (`enableScrollWheel` & `scrollWheelVelocity`)

Used together to enable scroll wheel scrolling, and set it's sensitivity/speed.

The first parameter takes a `bool`, enabling or disabling scroll wheel zooming. The second takes a `double`, which is used as a multiplier for changing the zoom level internally.

```dart
        enableScrollWheel: true,
        scrollWheelVelocity: 0.005,
```

Defaults to `true` and 0.005.

## When Position Changed (`onPositionChanged`)

Takes a function with two arguments. Gets called whenever the map position is changed, even if it is not changed by the user.

```dart
        onPositionChanged: (MapPosition position, bool hasGesture) {
            // Your logic here. `hasGesture` dictates whether the change
            // was due to a user interaction or something else. `position` is
            // the new position of the map.
        }
```

## When Map Tapped (`onTap`)

Takes a function with one argument. Gets called whenever the the user taps/clicks/presses on the map.

```dart
        onTap: (TapPosition position, LatLng location) {
            // Your logic here. `location` dictates the coordinate at which the user tapped.
        }
```

## When Map Ready (`onMapReady`)

See [#usage-in-initstate](../controller.md#usage-in-initstate "mention") before using this callback.

This callback can be registered if you need to do something with the map controller as soon as the map is available and initialized; generally though it isn't needed and the map is available after first build.

Takes a function with zero arguments. Gets called from the `initState()` method of the `FlutterMap`.
