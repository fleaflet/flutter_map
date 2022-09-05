# Layers

As briefly described in [#map-widget](../basics.md#map-widget "mention"), the `children` property takes a list of `Widget`s, which will be stacked on top of each other (last on top). These can be any `Widget`, such as a `FutureBuilder` or `StreamBuilder`, but are usually `Layer`s which are provided by this library or plugins.

There is also the `nonRotatedChildren` property, which work similarly as their 'rotatable' counterpart, but - as the name suggests - do not get rotated as the map gets rotated. For example, the [`AttributionWidget`](attribution-layer.md) should be used inside `nonRotatedChildren` instead of `children`, as it needs to remain vertical and therefore readable.

As a minimum, all maps should have a [tile-layer](tile-layer/ "mention"), as this is what actually displays any map. Other layers are available, such as markers/waypoints and lines.
