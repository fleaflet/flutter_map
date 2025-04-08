# Base Widget

```dart
FlutterMap(
    mapController: MapController(),
    options: MapOptions(),
    children: [],
);
```

Start by adding some [Broken link](broken-reference "mention") to `children`, then configure the map in [options](options/ "mention"). Additionally, if required, add a `MapController`: [controllers-and-cameras.md](programmatic-interaction/controllers-and-cameras.md "mention").

{% hint style="info" %}
The map widget will expand to fill its constraints. To avoid errors about infinite/unspecified sizes, ensure the map is contained within a constrained widget.
{% endhint %}

### Keep Alive

If the map is displayed lazily in something like a `PageView`, changing the page and unloading the map will cause it to reset to its [initial positioning](options/#initial-positioning).

To prevent this, set `MapOptions.keepAlive` `true`, which will activate an internal `AutomaticKeepAliveClientMixin`. This will retain the internal state container in memory, even when it would otherwise be disposed.
