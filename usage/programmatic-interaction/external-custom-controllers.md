# External Custom Controllers

For more information about what a `MapController` is, and when it is necessary to set one up in this way, see:

{% content-ref url="controllers-and-cameras.md" %}
[controllers-and-cameras.md](controllers-and-cameras.md)
{% endcontent-ref %}

***

## Basic Setup

The `FlutterMap.controller` parameter takes an externally intialised `MapController` instance, and attaches it to the map.

```dart
// Within a widget
final mapController = MapController();

@override
Widget build(BuildContext context) =>
    FlutterMap(
        mapController: mapController,
        // ...
    );
```

{% hint style="success" %}
An externally attached controller will be accurately reflected when depending on the `MapController` aspect.
{% endhint %}

{% hint style="warning" %}
It is not safe to assume that the `MapController` is ready to use as soon as an instance has been initialised, for example within `initState`.

See below for more information.
{% endhint %}

## Usage Before Attachment (eg. Within `initState`)

It is not safe to assume that the `MapController` is ready to use as soon as an instance has been initialised, for example within `initState`.

It must first be attached to the `FlutterMap`, which could take up to multiple frames to occur (similar to the way a `ScrollController` is attached to a scrollable view). It helps to avoid errors by thinking of the controller in this way.

{% hint style="warning" %}
Use of the `MapController` before it has been attached to a `FlutterMap` will result in an error being thrown, usually a `LateInitialisationError`.
{% endhint %}

{% hint style="success" %}
It is usually safe to use a controller from within a callback manually initiated by the user without further complications.
{% endhint %}

For example, it is sometimes necessary to use a controller in the `initState()` method (for example to [attach an event listener](listen-to-events.md)). However, because this method executes before the widget has been built, a controller defined here will not be ready for use.&#x20;

Instead, use the `MapOptions.onMapReady` callback. At this point, it is guaranteed that the controller will have been attached. You could also use this method to complete a `Completer` (and `await` its `Future` elsewhere) if you need to use it elsewhere.

```dart
final mapController = MapController();

@override
void initState() {
    // Cannot use `mapController` safely here
}

@override
Widget build(BuildContext context) {
    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
            onMapReady: () {
                mapController.mapEventStream.listen((evt) {}); // for example
                // Any* other `MapController` dependent methods
            },
        ),
    );
}
```

{% hint style="warning" %}
`MapController` methods that change the position of the map should not be used directly (not as a result of another callback) in `onMapReady` - see [issue #1507](https://github.com/fleaflet/flutter\_map/issues/1507). This is an unsupported and usually unnecessary usecase.
{% endhint %}

## Usage Within A State System/Model

{% hint style="danger" %}
Don't define/intialise the a `MapController` within a class or widget that doesn't also contain the `FlutterMap`, such as a state model (eg. `ChangeNotifier`), then try to use it by querying the state in the `FlutterMap.controller` parameter.
{% endhint %}

Instead, some extra care should be taken, which may feel a little backwards at first. The state model should be used AFTER the normal setup.

1. Setup the controller as in [#basic-setup](external-custom-controllers.md#basic-setup "mention"), where the `MapController` is defined & initialised directly adjacent to the `FlutterMap`
2. In your state model, create a nullable (and initially uninitialised) `MapController` containing field
3. Follow [#usage-before-attachment-eg.-within-initstate](external-custom-controllers.md#usage-before-attachment-eg.-within-initstate "mention") to setup an `onMapReady` callback. Then within this callback, set the state model field.

It may then be beneficial to unset the state model field when the controller is disposed: it should be disposed when the `FlutterMap` is disposed, which should occur just before the widget building the `FlutterMap` is disposed. Therefore, you can override the `dispose` method.

## Animation

Whilst animated movements through `MapController`s aren't built-in, the [community maintained plugin `flutter_map_animations`](https://github.com/TesteurManiak/flutter\_map\_animations) provides this, and much more!
