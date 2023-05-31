# Event Handling

{% hint style="info" %}
If building a custom layer ([creating-new-layers.md](../plugins/making-a-plugin/creating-new-layers.md "mention")), consider using `FlutterMapState` directly instead.
{% endhint %}

When changes happen to `FlutterMap`'s internal state, such as a change to the current position or zoom, it emits a `MapEvent`, which can be handled by you.

## Catching All Events

There's two ways to catch all emitted `MapEvent`s, and use them/the `Stream<MapEvent>` directly.

These methods expose the raw `MapEvent`, and is recommended in cases where multiple events need to be caught, or there's no more specific callback method available in `MapOptions`.

* Listening to a [`MapController`](controller.md)'s `mapEventStream`
* Specifying a callback method in `MapOptions.onMapEvent`

## Catching Specific Events

If only a couple of events need to be caught, such as just an `onTap` handler, it is possible to avoid handling the raw `Stream` of `MapEvent`s. Instead, `MapOptions` has callbacks available for the following events:

* `onTap`
* `onLongPress`
* `onPositionChanged`
* `onPointerDown`/`onPointerUp`/`onPointerHover`/`onPointerCancel`
* `onMapReady`\
  Primarily used for advanced `MapController` [#usage-in-initstate](controller.md#usage-in-initstate "mention")
