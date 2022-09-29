# Controller

The `mapController` property takes a `MapController`, and whilst it is optional, it is strongly recommended for any map other than the most basic. It allows you to programmatically interact with the map, such as panning, zooming and rotating.

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

It is a fairly common requirement to need to use the `MapController` before the map has been built, or to initialise a listener for one of it's streams inside the `initState()` `StatefulWidget` method. Unfortunately, this is not possible, as the map must be built for the controller to be attached.

### Recommended Usage

Luckily, Flutter provides methods to wait until the first frame has been built, which usually means the `FlutterMap` widget will have been built (see exception circumstances below). This makes it trivially easy to implement the desired behaviour.

{% code title="Recommended Usage" %}
```dart
@override
void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use `MapController` as needed
    });
}
```
{% endcode %}

### Alternative Usage

{% hint style="info" %}
For simplicity and readability, it is not recommended to use this method unless needed in your situation, although there should be little technical difference.
{% endhint %}

In some cases, the `FlutterMap` widget may not have been built on the first frame - for example when using a `FutureBuilder` around the map.

In this case, an alternative method is required to use the `MapController` on build. This method uses the [#when-map-ready-onmapready](options/other-options.md#when-map-ready-onmapready "mention") callback.

{% code title="Alternative Usage" %}
```dart
@override
Widget build(BuildContext context) =>
    FlutterMap(
        mapController: mapController,
        options: MapOptions(
            onMapReady: () {
                // Use `MapController` as needed
            },
        ),
    );
```
{% endcode %}

## Available Methods

For all the available methods and getters, see the [Full API Reference](https://pub.dev/documentation/flutter\_map/latest/flutter\_map/MapController-class.html).
