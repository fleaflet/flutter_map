# Tile Layer

{% hint style="info" %}
This page (and subpages) only talks about WMTS-supporting raster layers, which is the most common and default type of mapping.

For information about WMS-supporting layers or vector tiles, visit the [wms-usage.md](../wms-usage.md "mention") page.
{% endhint %}

A tile layer displays raster map tiles in a grid pattern, from a tile source such as a remote server or file system. This might look something like this:

```dart
FlutterMap(
    options: MapOptions(),
    children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
    ],
),
```

{% hint style="danger" %}
You must comply to your tile server's ToS. Failure to do so may result in you being banned from their services.

The OpenStreetMap Tile Server (as used above) can be [found here](https://operations.osmfoundation.org/policies/tiles). Other servers may have different terms.

This package is not responsible for your misuse of another tile server.
{% endhint %}

{% content-ref url="recommended-options.md" %}
[recommended-options.md](recommended-options.md)
{% endcontent-ref %}

{% content-ref url="other-options.md" %}
[other-options.md](other-options.md)
{% endcontent-ref %}
