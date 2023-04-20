# Controller

The `mapController` property takes a `MapController`, and whilst it is optional, it is strongly recommended for any map other than the most basic. It allows you to programmatically interact with the map, such as panning, zooming and rotating.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapController-class.html" %}
Full API Reference
{% endembed %}

## Initialisation

To use a `MapController`, it must initialised and then passed to the `FlutterMap`. This attaches them until the widget is destroyed/disposed.

{% hint style="info" %}
If this method does not appear to work, try the methods below sequentially.
{% endhint %}

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

{% hint style="info" %}
If this method does not appear to work, try the method below.
{% endhint %}

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

## Animation

Whilst animated controllers aren't built-in, the [community maintained plugin `flutter_map_animations`](https://github.com/TesteurManiak/flutter\_map\_animations) provides the functionality.
