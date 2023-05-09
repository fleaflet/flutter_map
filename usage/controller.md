# Controller

The `mapController` property takes a `MapController`, and whilst it is optional, it is strongly recommended for any map other than the most basic. It allows you to programmatically interact with the map, such as panning, zooming and rotating.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapController-class.html" %}
Full API Reference
{% endembed %}

## Initialisation

To use a `MapController`, it must initialised and then passed to the `FlutterMap`. This attaches them until the widget is destroyed/disposed.

```dart
final mapController = MapController();

@override
Widget build(BuildContext context) =>
    FlutterMap(
        mapController: mapController,
        ...
    );
```

## Usage In `initState()`

It is a fairly common requirement to need to use the `MapController` in `initState()`, before the map has been built. Unfortunately, this is not possible, as the map must be built for the controller to be attached.

This isn't a problem however! The [#when-map-ready-onmapready](options/other-options.md#when-map-ready-onmapready "mention") callback is called once[^1] when the map is initialised, and the initialised map controller can be used freely within it.

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
