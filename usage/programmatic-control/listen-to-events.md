# Listen To Events

{% hint style="info" %}
To cause a widget inside `FlutterMap`'s context to rebuild when an [aspect](controller.md) changes, see [#id-2.-hooking-into-inherited-state](../../plugins/making-a-plugin/creating-new-layers.md#id-2.-hooking-into-inherited-state "mention").
{% endhint %}

When the state of a `MapCamera` changes, because of an update to its position or zoom, for example, a `MapEvent`, which can be handled by you.

## Catching All Events

There's two methods to catch all emitted `MapEvent`s. These methods expose the raw `MapEvent`, and is recommended in cases where multiple events need to be caught, or there's no more specific callback method available in `MapOptions` (see [#catching-specific-events](listen-to-events.md#catching-specific-events "mention")).

* Listening to a [`MapController`](controller.md)'s `mapEventStream`, which exposes events via a `Stream`
* Specifying a callback method in `MapOptions.onMapEvent`

## Catching Specific Events

If only a couple of events need to be caught, such as just an `onTap` handler, it is possible to avoid handling the raw `Stream` of `MapEvent`s. Instead, `MapOptions` has callbacks available for the following events:

* `onTap`
* `onLongPress`
* `onPositionChanged`
* `onPointerDown`/`onPointerUp`/`onPointerHover`/`onPointerCancel`
* `onMapReady`\
  Primarily used for advanced `MapController` [#usage-inside-initstate](controller.md#usage-inside-initstate "mention")

{% hint style="info" %}
The `MapEventTap` event may be emitted (or the `onTap` callback called) 250ms after the actual tap occurred, as this is the acceptable delay between the two taps in a double tap zoom gesture.

If this causes noticeable jank or a bad experience (for example, on desktop platforms), disable [`InteractiveFlag`](../options/interaction-options.md#flags)`.doubleTapZoom`:

```dart
options: MapOptions(
    interactiveFlags: ~InteractiveFlag.doubleTapZoom,
),
```

This disables the double tap handler, so the `MapEventTap` is emitted 'instantly' on tap.
{% endhint %}
