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
  // tileProvider: NetworkTileProvider(),
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

## Tile Providers

Need more control over the source of tiles, or how tiles are fetched?

{% content-ref url="tile-providers.md" %}
[tile-providers.md](tile-providers.md)
{% endcontent-ref %}

### `userAgentPackageName`

{% hint style="success" %}
Always specify the `userAgentPackageName` argument to avoid being blocked by your tile server.
{% endhint %}

It should be passed the application's package name, such as 'com.example.app'. This is important to avoid blocking by tile servers due to high-levels of unidentified traffic. If no value is passed, it defaults to 'unknown'.

This is passed through to the [`NetworkTileProvider`](tile-providers.md#networktileprovider) (if in use) in a suitably formatted string, where it forms the 'User-Agent' header, overriding any custom user agent specified in the HTTP client.

To override this behaviour, specify a 'User-Agent' key in the [`NetworkTileProvider`](tile-providers.md#networktileprovider)`.headers` property.

This is all ignored on the web, where the 'User-Agent' header cannot be changed due to a limitation of Dart/browsers.

[^1]: [#useragentpackagename](./#useragentpackagename "mention")
