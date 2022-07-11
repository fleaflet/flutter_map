# Tile Layer

{% hint style="info" %}
This page only talks about WMTS-supporting raster layers, which is the most common and default type of mapping.

For information about WMS-supporting layers or vector tiles, visit the [WMS Usage](../wms-usage.md) page.
{% endhint %}

As explained in the [How Does It Work?](../../../getting-started/explanation.md) page, tiles for a map in 'flutter\_map' are provided by tile providers that go inside of a `TileLayerOptions()`. That might look something like this:

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
    ],
),
```

Each subpage has a few options, split into categories, to make them easier to refer to.
