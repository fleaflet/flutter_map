# The Basics

## Map Widget

```dart
FlutterMap(
    controller: MapController(),
    options: MapOptions(),
    children: [],
),
```

This is the main widget for this library, and it takes three main properties. options, children/layers, and a map controller which you can use to control the map from behind the scenes. These will be described in the following sections.

*   ``[`options`](options/) (required)

    Takes a `MapOptions` that is used to configure overall map options and options that don't directly affect appearance.
*   ``[`children`](layers/) (required)

    Takes a list of `Widget`s that will be displayed on the map. These can be any widget, but are usually map layers.
*   ``[`mapController`](controller.md) (optional)

    Takes a `MapController` that can be used to programmatically control the map, as well as listen to an events `Stream`.

## Placement Recommendations

It is recommended to make the map as large as possible, to allow it to display a lot of useful information easily.

As such, we recommend using a depth-based layout (eg. using `Stack`s) instead of a flat-based layout (eg. using `Column`s). The following 3rd party packages might help with creating a modern design:

* [https://pub.dev/packages/backdrop](https://pub.dev/packages/backdrop)
* [https://pub.dev/packages/sliding\_up\_panel](https://pub.dev/packages/sliding\_up\_panel)
* [https://pub.dev/packages/material\_floating\_search\_bar](https://pub.dev/packages/material\_floating\_search\_bar)

If you need to restrict the widget's size, you won't find a `height` or `width` property. Instead, use a `SizedBox` or `Column`/`Row` & `Expanded`.
