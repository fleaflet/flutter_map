# Tile Layer

The basis of any map is a `TileLayer`, which displays square raster images in a continuous grid, sourced from the Internet or a local file system.

flutter\_map supports [wms-usage.md](wms-usage.md "mention"), but most map tiles are accessed through Slippy Map/CARTO/XYZ URLs.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/TileLayer-class.html" %}

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
  // Plenty of other options available!
),
```

{% hint style="warning" %}
You must comply with the appropriate restrictions and terms of service set by your tile server. Always read the ToS before using a tile server. Failure to do so may lead to any punishment, at the tile server's discretion.

This library and/or the creator(s) are not responsible for any violations you make using this package.

_The OpenStreetMap Tile Server (as used above) ToS can be_ [_found here_](https://operations.osmfoundation.org/policies/tiles)_. Other servers may have different terms._
{% endhint %}

## URL Template

{% hint style="success" %}
This parameter must be specified unless [`wmsOptions`](wms-usage.md) is specified.
{% endhint %}

The URL template is a string that contains placeholders, which, when filled in, create a URL/URI to a specific tile.

Specifically, flutter\_map supports the Slippy Map format, sometimes referred to as CARTO or Raster XYZ. Tiles are referred to by their zoom level, and position on the X & Y axis. For more information, read [explanation](../../getting-started/explanation/ "mention").

These templates are usually documented by your tile server, and will always include the following placeholders:

* `{x}`: x axis coordinate
* `{y}`: y axis coordinate
* `{z}`: zoom level

Sometimes, they also include:

* `{s}`: [#subdomains](./#subdomains "mention")
* `{r}`: [#retina-mode](./#retina-mode "mention")

Additional placeholders can also be added freely to the template, and are filled in with the specified values in `additionalOptions`. This can be used to easier add switchable styles or access tokens, for example.

### Subdomains

Some tile servers provide mirrors/redirects of the main tile server on/via subdomains, such as 'a', 'b', 'c'.

These were necessary to bypass browsers' limitations on simultaneous HTTP connections, thus increasing the number of tiles that can load at once.

To use subdomains, add the `{s}` placeholder, and specify the available subdomains in `TileLayer.subdomains`. flutter\_map will then fill the placeholder with one of these values based on internal logic.

{% hint style="warning" %}
Subdomains are now usually [considered redundant](https://github.com/openstreetmap/operations/issues/737) due to the usage of HTTP/2 & HTTP/3 which don't have the same restrictions.

Usage of subdomains will also hinder Flutter's ability to cache tiles, potentially leading to increased tile requests and costs.

If the server supports HTTP/2 or HTTP/3 ([how to check](https://stackoverflow.com/a/71288871/11846040)), avoid using subdomains.
{% endhint %}

### Retina Mode

Retina mode improves the resolution of map tiles, an effect particularly visible on high density displays.

Raster map tiles can look pixelated (especially on high density displays), so some servers support [high-resolution "@2x" tiles](https://wiki.openstreetmap.org/wiki/High-resolution\_tiles), which are tiles at twice the resolution of normal tiles. However, not all tile servers support this, so flutter\_map can  simulate retina behaviour.

It is recommended to enable retina mode on high density displays (especially where the server natively supports retina tiles). This can be done by calling `RetinaMode.isHighDensity` with the current `BuildContext`, and passing the result to `TileLayer.retinaMode`.

If the `{r}` placeholder is present in the the `urlTemplate`, and `retinaMode` is enabled, then it will be filled with "@2x".\
If it is not present, but `retinaMode` is enabled, then flutter\_map will simulate retina behaviour by requesting four tiles at a larger zoom level and combining them together in place of one.&#x20;

{% hint style="warning" %}
Note that simulating retina mode will increase tile requests, decrease the effective maximum zoom by 1, and may cause unusual scaling of tiles and their relative contents.

Always prefer the server's native retina tiles where available.
{% endhint %}

### Fallback URL Template

It's also possible to specify a `fallbackUrl` template, used if fetching a tile from the primary `urlTemplate` fails (which has the same format as this).

{% hint style="warning" %}
Specifying a `fallbackUrl` does have negative effects on performance and efficiency. Avoid specifying `fallbackUrl` unless necessary.

See in-code documentation and [tile-providers.md](tile-providers.md "mention") for more information.
{% endhint %}

{% hint style="warning" %}
Certain `TileProvider`s may not support/provide any functionality for `fallbackUrl` template.
{% endhint %}

## `userAgentPackageName`

{% hint style="success" %}
Although it is programatically optional, always specify the `userAgentPackageName` argument to avoid being blocked by your tile server.
{% endhint %}

This parameter should be passed the application's package name, such as 'com.example.app'. This is important to avoid blocking by tile servers due to high-levels of unidentified traffic. If no value is passed, it defaults to 'unknown'.

This is then formatted into a 'User-Agent' header, and appended to the `TileProvider`'s `headers` map, if it is not already present.

This is ignored on the web, where the 'User-Agent' header cannot be changed due to a limitation of Dart/browsers.

## Tile Providers

{% hint style="success" %}
If a large proportion of your users use the web platform, it is preferable to use `CancellableNetworkTileProvider`, instead of the default `NetworkTileProvider`. It may also be beneficial to use this tile provider on other platforms as well.

See [#cancellablenetworktileprovider](tile-providers.md#cancellablenetworktileprovider "mention") for more information.
{% endhint %}

Need more control over how the URL template is interpreted and/or tiles are fetched? You'll need to change the `TileProvider`.

{% content-ref url="tile-providers.md" %}
[tile-providers.md](tile-providers.md)
{% endcontent-ref %}

## Tile Update Transformers

\<blank>
