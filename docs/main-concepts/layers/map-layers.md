---
id: map-layers
sidebar_position: 1
---

# Map Layers

The `children` property takes a list of widgets that should be extensions of `LayerOptions`. The actual visual part of the map comes from layers. Multiple layers can be stacked on top of each other, to add other functionality on top of the basic map view.

Layers are either tile layers (with tile providers), polygons, polylines, markers or any other custom layer or layer added by a supported plugin. However, if you wanted to show a widget that didn't need to interact with the map on top of the map (such as a compass), it would be recommended to place the `FlutterMap()` inside a `Stack()`, and then display that widget over the map in the stack.

The following sub-pages detail layers that you're likely to use on the map.
