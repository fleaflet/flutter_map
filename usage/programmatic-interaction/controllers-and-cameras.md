# Controllers & Cameras

flutter\_map makes use of `InheritedModel` to share 3 'aspects' with its built children:

* `MapController`: use to programatically control the map camera & access some helper functionality - **control camera**
* `MapCamera`: use to read the current state/position of the map camera & access some helper functionality that depends on the camera (such as `latlngToPoint`) - **read camera**

{% hint style="info" %}
`MapOptions` is also an aspect, which reflects the `MapOptions` defined on the `FlutterMap.options` parameter.

However, it is mostly irrelevant, except for when [creating-new-layers.md](../../plugins/making-a-plugin/creating-new-layers.md "mention").
{% endhint %}

## Accessing Aspects Within Descendants

All 3 aspects can be retrieved from within the context of a `FlutterMap`, which all _built_ descendants should have access to. This usually means from within a layer: anywhere where there is at least one 'visible' builder method between the `FlutterMap` and the invocation.

Use the static `of` (or null-safe `maybeOf`) method to access the inherited aspect. For example, to access the `MapCamera`:

```dart
final inheritedCamera = MapCamera.of(context);
```

This will attach the widget to the state of the map, causing it to rebuild whenever the depended-on aspects change. See [#id-2.-hooking-into-inherited-state](../../plugins/making-a-plugin/creating-new-layers.md#id-2.-hooking-into-inherited-state "mention") for more information.

{% hint style="warning" %}
Using this method directly in the `children` list (not inside another widget), and in any `MapOptions` callback, is not possible: there is no\* builder method between the `FlutterMap` and the `children` or callback.

Instead, follow [#accessing-aspects-elsewhere](controllers-and-cameras.md#accessing-aspects-elsewhere "mention"), or, wrap the necessary layers with a `Builder` widget.\
For example, the code snippet below hides a `TileLayer` when above zoom level 13:

```dart
children: [
    Builder(
        builder: (context) {
            if (MapCamera.of(context).zoom < 13) return SizedBox.shrink();
            return TileLayer();
        },
    ),
],
```
{% endhint %}

## Accessing Aspects Elsewhere

### `MapCamera`

To access the `MapCamera` outside of a `FlutterMap` descendant, first [setup an external `MapController`, as guided below](controllers-and-cameras.md#mapcontroller).

Then use the `camera` getter on the `MapController` instance.

{% hint style="warning" %}
Avoid using this method to access the camera when `MapCamera.of()` is available.
{% endhint %}

### `MapController`

For more information about correctly setting up an external(ly accessible) `MapController`, see:

{% content-ref url="external-custom-controllers.md" %}
[external-custom-controllers.md](external-custom-controllers.md)
{% endcontent-ref %}

### `MapOptions`

{% hint style="info" %}
It is not possible to access the `MapOptions` in this way outside of `FlutterMap` descendants.

This is because it is not changed by `FlutterMap`, and so that would be unnecessary.
{% endhint %}
