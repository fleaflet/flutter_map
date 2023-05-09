# Controller

To programatically interact with the map (such as panning, zooming and rotating) and receive it's events, you'll need a `MapController`.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapController-class.html" %}

{% hint style="warning" %}
If building a custom layer ([creating-new-layers.md](../plugins/making-a-plugin/creating-new-layers.md "mention")), consider using `FlutterMapState` directly instead.
{% endhint %}

## Initialisation

To use a `MapController`, it must initialised like any other object and then passed to the `FlutterMap`. This attaches them until the map is disposed.

```dart
final mapController = MapController();

@override
Widget build(BuildContext context) =>
    FlutterMap(
        mapController: mapController,
        ...
    );
```

{% hint style="warning" %}
Avoid disconnecting the map from the controller, as it can cause problems. If you need to change the map's contents:

* Change its `children` (layers) individually
* Re-initialise a new `MapController`, and keep it in an external state system

If you still get issues, and `FlutterMap` is located inside a `PageView`, `ListView` or another complex lazy layout, try setting `keepAlive` `true` in `MapOptions`: [#permanent-rules](options.md#permanent-rules "mention").
{% endhint %}

## Usage In `initState()`

It is a fairly common requirement to need to use the `MapController` in `initState()`, before the map has been built. Unfortunately, this is not possible, as the map must be built for the controller to be attached.

This isn't a problem however! The `MapOptions` contains an `onMapReady` callback (see [#event-handling](options.md#event-handling "mention")) is called once[^1] when the map is initialised, and the initialised map controller can be used freely within it.

```dart
final mapController = MapController();

@override
Widget build(BuildContext context) =>
    FlutterMap(
        mapController: mapController,
        options: MapOptions(
            onMapReady: () {
                mapController.mapEventStream.listen((evt) {});
                // And any other `MapController` dependent non-movement methods
            },
        ),
    );
```

{% hint style="info" %}
It may also be possible to use `SchedulerBinding` or `WidgetsBinding` in `initState` to run a method after the first frame has been built, as detailed here: [https://stackoverflow.com/a/64186549/11846040](https://stackoverflow.com/a/64186549/11846040). You'll probably see this approach in many older projects.

That method will, however, not work if the map is not built on the first frame. This may be the case if it is, for example, in a `FutureBuilder`.
{% endhint %}

{% hint style="warning" %}
`MapController` methods that change the position of the map should not be used instantly in `onMapReady` - see [issue #1507](https://github.com/fleaflet/flutter\_map/issues/1507).

Using them as a reaction to a map event is still fine.
{% endhint %}

## Animation

Whilst animated movements through `MapController`s aren't built-in, the [community maintained plugin `flutter_map_animations`](https://github.com/TesteurManiak/flutter\_map\_animations) provides this, and much more!

The example application also includes a page demonstrating a custom animated map movement.

[^1]: It may be called more than once in some circumstances.\
    If this is the case, use a flag variable, and only carry out the actions is the flag has not already been set.
