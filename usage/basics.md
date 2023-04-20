# Base Widget

```dart
FlutterMap(
    mapController: _mapController,
    options: MapOptions(),
    children: [],
    nonRotatedChildren: [],
);
```

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th data-type="select"></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><code>options</code> (<code>MapOptions</code>)</td><td></td><td>Configure options that don't directly affect the appearance of the map, such as starting location and maximum zoom limit.</td><td><a href="options/">options</a></td></tr><tr><td><code>mapController</code></td><td></td><td>Attach a controller object to control the map programatically, including panning and zooming.</td><td><a href="controller.md">controller.md</a></td></tr><tr><td><code>children</code></td><td></td><td>Takes a <code>List</code> of <code>Widgets</code> (usually a dedicated 'layer') to display on the map, such as tile layers or polygon layers,</td><td><a href="layers.md">layers.md</a></td></tr><tr><td><code>nonRotatedChildren</code></td><td></td><td>Similar to <code>children</code>, but these don't rotate or move with the other layers.</td><td></td></tr></tbody></table>

## Placement Recommendations

It is recommended to make the map as large as possible, to allow it to display a lot of useful information easily.

As such, we recommend using a depth-based layout (eg. using `Stack`s) instead of a flat-based layout (eg. using `Column`s). The following 3rd party packages might help with creating a modern design:

* [https://pub.dev/packages/backdrop](https://pub.dev/packages/backdrop)
* [https://pub.dev/packages/sliding\_up\_panel](https://pub.dev/packages/sliding\_up\_panel)
* [https://pub.dev/packages/material\_floating\_search\_bar](https://pub.dev/packages/material\_floating\_search\_bar)

If you must restrict the widget's size, you won't find a `height` or `width` property. Instead, use a `SizedBox` or `Column`/`Row` & `Expanded`.
