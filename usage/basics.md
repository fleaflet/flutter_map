# Base Widget

```dart
FlutterMap(
    mapController: MapController(),
    options: MapOptions(),
    children: [],
);
```

Start by adding some [Broken link](broken-reference "mention") to `children`, then configure the map in [options](options/ "mention"). Additionally, if required, add a `MapController`: [controllers-and-cameras.md](programmatic-interaction/controllers-and-cameras.md "mention").

## Placement Recommendations

It is recommended to make the map as large as possible, to allow it to display a lot of useful information easily.

As such, we recommend using a depth-based layout (eg. using `Stack`s) instead of a flat-based layout (eg. using `Column`s). The following 3rd party packages might help with creating a modern design:

* [https://pub.dev/packages/backdrop](https://pub.dev/packages/backdrop)
* [https://pub.dev/packages/sliding\_up\_panel](https://pub.dev/packages/sliding\_up\_panel)
* [https://pub.dev/packages/material\_floating\_search\_bar\_2](https://pub.dev/packages/material\_floating\_search\_bar\_2)

If you must restrict the widget's size, you won't find a `height` or `width` property. Instead, use a `SizedBox` or `Column`/`Row` & `Expanded`.

{% hint style="info" %}
The map widget will expand as much as possible.

To avoid errors about infinite/unspecified dimensions, ensure the map is contained within a constrained widget.
{% endhint %}

### Keep Alive

If the map is displayed lazily in something like a `PageView`, changing the page and unloading the map will cause it to reset to its [initial positioning](options/#initial-positioning).

To prevent this, set `MapOptions.keepAlive` `true`, which will activate an internal `AutomaticKeepAliveClientMixin`. This will retain the internal state container in memory, even when it would otherwise be disposed.
