# Get Camera

The `MapCamera` object describes the map's current viewport. It does not provide methods to change it: that is the responsibility of a [`MapController`](controller.md).

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapCamera-class.html" %}

{% hint style="info" %}
The `MapCamera` object also provides access to some other helpful methods that depend on it, such as `pointToLatLng` & `latLngToPoint`.
{% endhint %}

## Usage Inside Of A `FlutterMap` Child

To get the camera from within the context of a `FlutterMap` widget, use `MapCamera.of(context)`.

{% hint style="info" %}
Calling this method in a `build` method will cause the widget to automatically rebuild when the `MapCamera` changes. See [#2.-hooking-into-inherited-state](../../plugins/making-a-plugin/creating-new-layers.md#2.-hooking-into-inherited-state "mention") for more information.

If this behaviour is unwanted, use [#single-time](get-camera.md#single-time "mention") instead.
{% endhint %}

If this throws a `StateError`, try wrapping the concerned widget in a `Builder`, to ensure the `FlutterMap` widget is parenting the `BuildContext`. If this has no effect, use [#usage-outside-of-fluttermap](get-camera.md#usage-outside-of-fluttermap "mention") instead.

## Usage Outside Of `FlutterMap`

### Single Time

To get the camera from outside the context of the `FlutterMap` widget, you'll need to setup a `MapController` first: see [controller.md](controller.md "mention") > [#usage-outside-of-fluttermap](controller.md#usage-outside-of-fluttermap "mention").

Then, use the `.camera` getter.

{% hint style="warning" %}
Avoid using `MapController.of(context).camera` from within the context of `FlutterMap`, as it is redundant and less performant than using `MapCamera.of(context)` directly.
{% endhint %}

### Listen To Changes

{% content-ref url="listen-to-events.md" %}
[listen-to-events.md](listen-to-events.md)
{% endcontent-ref %}
