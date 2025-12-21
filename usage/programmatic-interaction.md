# Programmatic Interaction

In addition to the user interacting with the map, for example by using their cursor, trackpad, or touchscreen, the map can be controlled programmatically.

{% hint style="warning" %}
Changing the state of `MapOptions.initial*` will not update the map. Map control in 'flutter\_map' is imperative.
{% endhint %}

Programmatic interaction consists of two parts: reading and setting information about the map.

To use programmatic interaction, it's important to understand the difference between the map's 'camera' and the map's 'controller', and their relationship.

## Camera

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapCamera-class.html" %}

The map's camera - or `MapCamera` - is an object that holds information to be read about the map's current viewport, such as:

* the coordinates of the geographic location at the `center` of the map
* the current `rotation` of the map (in degrees, where 0° is North)
* the current `zoom` level of the map

For example:

```dart
final MapCamera mapCamera = getMapCamera(); // See below
print(mapCamera.zoom);
```

## Controller

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapController-class.html" %}

Similarly to other map client projects, the controller - `MapController` - allows the map's viewport/camera to be modified/set using methods, such as:

* move the camera to a new location and zoom level, using either:
  * `move`, which accepts a new center coordinate and zoom level
  * `fitCamera`, which allows more advanced positioning using coordinate boundaries and screen-space padding
* `rotate` the camera to a new number of degrees from North

For example:

```dart
final MapController mapController = getMapController(); // See below
mapController.move(LatLng(51.505, -0.124), 9); // Position the map to show London, UK
```

## Accessing the 'aspects'

Together, the `MapCamera` and `MapController` are two aspects of the `MapInheritedModel`.

{% hint style="info" %}
`MapOptions` is also an aspect of the same inherited model, but this is not useful here since it cannot be exposed outside of map layers.
{% endhint %}

{% tabs %}
{% tab title="From inside a map layer" %}
This means that you can get both the camera and the controller from within a layer of the map, given the map's `BuildContext`.

The `MapCamera.of` & `MapController.of` methods accept this context, and return their respective aspect. They also subscribe the layer for further updates: using `MapCamera.of` means that widget/layer will rebuild every time the `MapCamera` changes (for example, when the map's location changes).

For example:

```dart
return FlutterMap(
    // ...
    children: [
        Builder(
            builder: (context) {
                // This is a map layer
                final camera = MapCamera.of(context);
                final controller = MapController.of(context);
                
                // This will automatically update to display the current zoom level
                return Text(camera.zoom.toString());
            },
        ),
    ],
);
```

{% hint style="warning" %}
Using `MapController.of(context).camera` is an anti-pattern and not recommended.
{% endhint %}
{% endtab %}

{% tab title="From outside of the map" %}
If you want to access either aspect from outside of the map - for example, to reposition the map when the user presses a button, or to use the map's location in an API call - you'll need to:

{% stepper %}
{% step %}
### Declare an external `MapController`

The `MapController` object can be constructed, like in the example below. We recommend using a `StatefulWidget`.

{% hint style="info" %}
The `MapController` works similarly to a `ScrollController`.
{% endhint %}
{% endstep %}

{% step %}
### Attach the controller to the map

The default controller that `FlutterMap` uses and passes around internally can be overridden with the external controller using `FlutterMap.controller`.

For example:

<pre class="language-dart"><code class="lang-dart">// (`StatefulWidget` definition) ...

class _MapViewState extends State&#x3C;MapView> {
    final _mapController = MapController();
    
    @override
    Widget build(BuildContext context) {
        return FlutterMap(
<strong>            controller: _mapController,
</strong>            // ...
        );
    }
}
</code></pre>

{% hint style="warning" %}
The `MapController` does not become safe to use until after it has been fully initialised and attached to the map widget, which occurs during the first build of the map.

This means it cannot be used directly within `initState`, for example.

See [#the-controller-is-not-safe-to-use-until-attached](programmatic-interaction.md#the-controller-is-not-safe-to-use-until-attached "mention") for more information.
{% endhint %}
{% endstep %}
{% endstepper %}

Then, the external controller controls the map, and you can access the `MapCamera` from outside of the map using `MapController.camera`. For example:

```dart
double getCurrentZoomLevel(MapController controller) {
    return controller.camera.zoom;
}
```

### Pitfalls of an external controller

<details>

<summary>The controller is not safe to use until attached</summary>

Attachment to a map usually takes a single frame and is done in the initial widget build, but it's good practise not to assume this.

The controller definitely can not be used in `initState` (at least without adding a post-frame callback, which is not a recommended practise).

In most use cases, the controller will be used to respond to user actions, such as the `onPressed` callback of a button. In this case, it's usually safe to assume the controller is ready to use - unless, for example, there is a `FutureBuilder` wrapped around the `FlutterMap` which has not built the map yet.

If you need to hook into when the controller will be attached to the map, use `MapOptions.onMapReady`. For example:

```dart
final _mapControllerReady = Completer<void>();

return FlutterMap(
    mapController: _mapController,
    options: MapOptions(
        onMapReady: () {
            // `_mapController` safe to use
            _mapControllerReady.complete();
        },
    ),
);
```

{% hint style="warning" %}
`MapController` methods that control the map (such as changing its position) should not be used directly in `onMapReady` - see [issue #1507](https://github.com/fleaflet/flutter_map/issues/1507).

Configure the initial map position in `MapOptions` instead.
{% endhint %}

</details>

<details>

<summary>Construct the controller in the widget tree &#x26; don't pass it up the tree</summary>

To avoid issues, it's best practise to construct the `MapController` in the widget tree (for example, as a field on a `State`), either in a parent of the map-containing widget, or in the same widget.

Therefore, don't construct the controller directly in a state model, such as Provider or Bloc. Construct the controller as far up the widget tree as is necessary to ensure all widgets that need it are children, then use a dependency injection or inheritance to pass it to children (or pass it into a state model when constructing it).&#x20;

</details>

<details>

<summary>The <code>MapController</code> does not animate the map</summary>

When you use a method on the controller, the map state is updated immediately.

If you want to use animations, consider using the [community maintained plugin `flutter_map_animations`](https://github.com/TesteurManiak/flutter_map_animations).

</details>
{% endtab %}
{% endtabs %}

## Reacting to map events

To imperatively react to changes to the map camera, there's multiple methods available.

{% hint style="info" %}
Remember that when using `MapCamera.of`, that widget will automatically rebuild when the camera changes.
{% endhint %}

### Simple events

If you prefer a callback-based pattern and need to capture user interaction events with the widget (with limited information about the event or its effect on the map itself), the following callbacks are available through `MapOptions`:

* `onTap`
* `onLongPress`
* `onPointerDown`/`onPointerMove`/`onPointerUp`/`onPointerHover`/`onPointerCancel`

These callbacks are also available, which are not strictly caused by user interaction events and give information about the map, but are provided for ease-of-use:

* `onPositionChanged`: called when the map moves
* `onMapReady`: called when the `MapController` is attached

For example:

```dart
return FlutterMap(
    options: MapOptions(
        // ...
        onTap: (tapPosition, point) {
            final screenTapped = tapPosition.global;
            final coordinatesTapped = point;
        },
        onPositionChanged: (camera, hasGesture) {
            if (hasGesture) {
                disableUserLocationFollow();
            }
            print(camera.center);
        },
    ),
    // ...
);
```

{% hint style="info" %}
The `onTap` callback and `MapEventTap` event may be emitted 250ms after the actual tap occurred, as this is the acceptable delay between the two taps in a double tap zoom gesture.

If your project would benefit from a faster reaction to taps, disable the double tap zoom gesture, which will allow taps to be handled immediately:

```dart
options: MapOptions(
    interactionOptions: InteractionOptions(
        flags: ~InteractiveFlag.doubleTapZoom,
    ),
),
```
{% endhint %}

### Multiple or complex event handling

There's two methods to handle raw `MapEvent`s, which are emitted whenever the `MapCamera` changes, and contain detailed information, such as the source of the event, and, for some events, the old and new camera.

{% tabs %}
{% tab title="Using an options callback" %}
`MapOptions` has a callback named `onMapEvent`. For example:

```dart
options: MapOptions(
    onMapEvent: (evt) {
        if (evt is MapEventMove) {
            final oldCamera = evt.oldCamera;
            final newCamera = evt.newCamera;
        }
    },
),
```
{% endtab %}

{% tab title="Through an external controller" %}
In addition to controlling the map, the `MapController` also has a getter called `mapEventStream`. For example:

```dart
StreamSubscription<MapEvent> listenToMapEvents(MapController controller) {
    return mapController.mapEventStream.listen((evt) {
        if (evt is MapEventMove) {
            final oldCamera = evt.oldCamera;
            final newCamera = evt.newCamera;
        }
    });
}
```
{% endtab %}
{% endtabs %}
