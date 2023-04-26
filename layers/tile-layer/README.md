---
description: CARTO/XYZ/Slippy Map Only
---

# Tile Layer

The basis of any map is a `TileLayer`, which displays square raster images in a continuous grid, sourced from the Internet or a local file system.

flutter\_map supports [wms-usage.md](../wms-usage.md "mention"), but most map tiles are accessed through the CARTO/XYZ/Slippy Map standard, where the mapping library (flutter\_map) fills in XYZ placeholders in a URL.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/TileLayer-class.html" %}
Read the API documentation to find out all the available options
{% endembed %}

<pre class="language-dart"><code class="lang-dart">TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  <a data-footnote-ref href="#user-content-fn-1">userAgentPackageName</a>: 'dev.fleaflet.flutter_map.example',
),
</code></pre>

{% hint style="danger" %}
You must comply to your tile server's ToS. Failure to do so may result in you being banned from their services.

The OpenStreetMap Tile Server (as used above) can be [found here](https://operations.osmfoundation.org/policies/tiles). Other servers may have different terms.

This package is not responsible for your misuse of any tile server.
{% endhint %}

{% hint style="info" %}
It is possible to use more than one tile layer, and can be used with transparency/opacity.

The `children` list works like the children of a `Stack`: last is on top.
{% endhint %}

[^1]: This is a **strongly recommended** argument, as it describes your app to the tile server.

    Failure to specify this will result in your app's traffic being grouped with other unspecified/general flutter\_map traffic, meaning that your app is more liable to being blocked.
