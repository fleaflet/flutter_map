# Layers

As briefly described in [#map-widget](../basics.md#map-widget "mention"), both the `children` and `layers` property take layers, but each works differently.

The `children` property takes a list of `Widget`s, which will be stacked on top of each other (last on top). These can be any `Widget`, such as a `FutureBuilder` or `StreamBuilder`, but are usually `LayerWidget`s which are provided by this library. `LayerWidget`s have the property `options`, which takes a `LayerOptions`.

Alternatively, the `layers` property takes a list of `LayerOptions`, cutting out the `LayerWidget`. This was the older property available, and is no longer recommended for use. This is mainly because each `LayerOptions` cannot hold its own state, meaning a `setState()` call (or similar) will have to rebuild all layers, which is very inefficient.

There are also `nonRotatedChildren` and `nonRotatedLayers` properties, which work similarly as their 'rotatable' counterpart, but - as the name suggests - do not get rotated as the map gets rotated. For example, the [`AttributionWidget`](attribution-layer.md) should be used inside `nonRotatedChildren` instead of `children`.

{% hint style="info" %}
Many subpages will use the `layers` property for simplicity and conciseness. To use the `children` property, just wrap each `LayerOptions` with its respective `LayerWidget`.

We're working on updating this documentation as you read this!
{% endhint %}
