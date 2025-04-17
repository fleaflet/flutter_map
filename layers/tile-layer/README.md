# Tile Layer

{% hint style="danger" %}
## Complying with tile server terms

It is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.

The OpenStreetMap Tile Server, as is used for demonstration throughout this project, is **NOT free to use by everyone**. Their terms of service can be [found here](https://operations.osmfoundation.org/policies/tiles).

**Production apps should be extremely cautious about using this tile server**; other projects, libraries, and packages suggesting that OpenStreetMap provides free-to-use map tiles are incorrect. **The examples in this documentation do not necessarily create fully compliant maps.**
{% endhint %}

The basis of any map is a `TileLayer`, which displays square raster images in a continuous grid, sourced from the Internet or a local file system.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/TileLayer-class.html" %}

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
  // + many other options
),
```

## Recommended Setup

{% hint style="success" %}
Although setting up a basic tile layer couldn't be simpler, it helps to spend a little bit more time fine-tuning it! We recommend following these steps for every tile layer.
{% endhint %}

{% stepper %}
{% step %}
### Choose a map source

flutter\_map doesn't provide tiles, so you'll need to bring your own raster tiles! There's multiple different supported sources.

{% tabs %}
{% tab title="Slippy Map/CARTO (XYZ)" %}
If you have a URL with placeholders for X, Y, and Z values, this is probably what you need to set up. This is the most common format for raster tiles, although many satellite tiles will instead use WMS.

{% tabs %}
{% tab title="From a network tile server" %}
Set the `urlTemplate` parameter to the template provided by the tile server - usually it can be copied directly from an account portal or documentation. You may also need to copy an API/access key.

<details>

<summary>(Advanced) Fallback URL Template</summary>

It's also possible to specify a `fallbackUrl` template, used if fetching a tile from the primary `urlTemplate` fails (which has the same format as this). It follows the same format, and supports the same placeholders.

{% hint style="warning" %}
Specifying a `fallbackUrl` does have negative effects on performance and efficiency. Avoid specifying `fallbackUrl` unless necessary.

See in-code documentation and [tile-providers.md](tile-providers.md "mention") for more information.
{% endhint %}

{% hint style="info" %}
Some `TileProvider`s may not support/provide any functionality for `fallbackUrl` template.
{% endhint %}

</details>

#### Placeholders

As well as the standard XYZ placeholders in the template, the following placeholders may also be used:

* `{s}`: subdomains (see below)
* `{r}`: native retina mode - see step 4 for more information
* `{d}`: reflects the `tileDimension` property (see below)

Additional placeholders can also be added freely to the template, and are filled in with the specified values in `additionalOptions`. This can be used to easier add switchable styles or access tokens, for example.

<details>

<summary>Subdomains</summary>

{% hint style="warning" %}
Subdomains are now usually [considered redundant](https://github.com/openstreetmap/operations/issues/737) due to the usage of HTTP/2 & HTTP/3 which don't have the same restrictions.

Usage of subdomains will also hinder Flutter's ability to cache tiles, potentially leading to increased tile requests and costs.

If the server supports HTTP/2 or HTTP/3 ([how to check](https://stackoverflow.com/a/71288871/11846040)), avoid using subdomains.
{% endhint %}

Some tile servers provide mirrors/redirects of the main tile server on/via subdomains, such as 'a', 'b', 'c'.

These were necessary to bypass browsers' limitations on simultaneous HTTP connections, thus increasing the number of tiles that can load at once.

To use subdomains, add the `{s}` placeholder, and specify the available subdomains in `TileLayer.subdomains`. flutter\_map will then fill the placeholder with one of these values based on internal logic.

</details>

<details>

<summary>Tile Dimension</summary>

Some tile servers will use 512x512px tiles instead of 256x256px, such as Mapbox. Using these larger tiles can help reduce tile requests, and when combined with [Retina Mode](./#retina-mode), it can give the same resolution.

To use these tiles, set `tileDimension` to the actual dimensions of the tiles (otherwise they will appear to small), such as `512`. Also set `zoomOffset` to the result of `-((d/256) - 1)` - ie. `-1` for x512px tiles (otherwise they will appear at the wrong geographical locations).

The `{d}` placeholder/parameter may also be used in the URL to pass through the value of `tileDimension`.

</details>
{% endtab %}

{% tab title="From offline/on-device sources" %}
See [offline-mapping.md](../../tile-servers/offline-mapping.md "mention") for detailed info and potential approaches to supporting offline users.

#### From the app's assets (bundled offline)

1. Set the `tileProvider` to `AssetTileProvider()`
2.  Set the `urlTemplate` to the path to each tile from the assets directory, using the placeholders as necessary. For example:

    ```
    assets/map/{z}/{x}/{y}.png
    ```
3. Add each lowest level directory to the pubspec's assets listing.&#x20;

#### From the filesystem (filesystem/dynamic offline)

1. Set the `tileProvider` to `FileTileProvider()`
2. Set the `urlTemplate` to the path to each tile within the filesystem, using the placeholders as necessary
3. Ensure the app has any necessary permissions to read from the filesystem
{% endtab %}
{% endtabs %}
{% endtab %}

{% tab title="WMS" %}
WMS tile servers have a base URL and a number of layers. flutter\_map can automatically put these together to fetch the correct tiles.

Create a `WMSTileLayerOptions` and pass it to the `wmsOptions` parameter. Define the `baseUrl` as needed, and for each layer string, add it as an item of a list passed to `layers`. You may also need to change other options, check the [full API documentation](https://pub.dev/documentation/flutter_map/latest/flutter_map/WMSTileLayerOptions-class.html), or follow the [example app](https://github.com/fleaflet/flutter_map/blob/master/example/lib/pages/wms_tile_layer.dart).

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/WMSTileLayerOptions-class.html" %}
{% endtab %}
{% endtabs %}
{% endstep %}

{% step %}
### Identify your client

It's important to identify your app to tile servers using the HTTP 'User-Agent' header (if they're not your own, and especially if their free or their ToS specifies to do so). This avoids potential issues with the tile server blocking your app because they do not know why so many tiles are being requested by unidentified clients - this can escalate to flutter\_map being blocked as a whole if too many apps do not identify themselves

Set the `userAgentPackageName` parameter to your app's package name (such as `com.example.app` or any other unique identifying information). flutter\_map will identify your client to the server via the header as:

`flutter_map (<packageName or 'unknown'>)`

{% hint style="info" %}
In some cases, you may be able to skip this step:

* Your app runs solely on the web: the 'User-Agent' header cannot be changed, and will always identify your users' browsers
* The tile server is your own, or you are using entirely offline mapping
{% endhint %}
{% endstep %}

{% step %}
### Manually set up a tile provider to optimize tile loading

The `TileProvider` is responsible for fetching tiles for the `TileLayer`. By default, the `TileLayer` creates a `NetworkTileProvider` every time it is constructed. `TileProvider`s are attached to the lifecycle of the `TileLayer` they are used within, and automatically disposed when their `TileLayer` is disposed.

However, this can cause performance issues or glitches for many apps. For example, the HTTP client can be manually constructed to be long-living, which will keep connections to a tile server open, increasing tile loading speeds.

<figure><img src="../../.gitbook/assets/Tile Provider Optimization.svg" alt="Flowchart describing the best method to optimize a tile layer &#x26; tile provider setup. Is your &#x60;FlutterMap&#x60; or &#x60;TileLayer&#x60; rebuilt (frequently)? Or, are you using a different tile provider to the default? If not, don&#x27;t worry about it, the &#x60;TileLayer&#x60; will do it for you. Otherwise, does your tile provider (or its properties) change frequently, or depend on the build method? If it does, construct a tile provider within the build method if necessary, but manually create a HTTP client outside of the build method and pass it in. Otherwise, do you need to reuse your tile provider across multiple different (volatile) tile layers? If you do, construct a tile provider outside of the build method, but also manually create a HTTP client and pass it in. Otherwise, just construct a tile provider as normal, but outside of the build method."><figcaption></figcaption></figure>

If you're not using a different tile provider, such as one provided by a plugin or one for offline mapping, then installing and using the official `CancellableNetworkTileProvider` plugin may be beneficial, especially on the web. See [#cancellablenetworktileprovider](tile-providers.md#cancellablenetworktileprovider "mention") for more information.

See [tile-providers.md](tile-providers.md "mention") for more information about tile providers generally.
{% endstep %}

{% step %}
### Enable retina mode (if supported by your tiles)

Retina mode improves the resolution of map tiles, an effect particularly visible on high density (aka. retina) displays.

Raster map tiles can look especially pixelated on retina displays, so some servers support [high-resolution "@2x" tiles](https://wiki.openstreetmap.org/wiki/High-resolution_tiles), which are tiles at twice the resolution of normal tiles.

Where the display is high density, and the server supports retina tiles - usually indicated by an `{r}` placeholder in the URL template - it is recommended to enable retina mode.

To enable retina mode in these circumstances, use the following:

```dart
    retinaMode: RetinaMode.isHighDensity(context),
```

Note that where tiles are larger than the standard x256px (such as x512px), retina mode can help make them appear very similar to x256px tiles, but still retain the other benefits of larger tiles. In this case, consider fixing `retinaMode` to `true`, depending on your own tests.

<details>

<summary>Emulating retina mode</summary>

It is also possible to emulate retina mode, even when the server does not natively support it. If `retinaMode` is `true`, and no `{r}` placeholder is present, flutter\_map will emulate it by requesting four tiles at a larger zoom level and combining them together in place of one.

Emulating retina mode has multiple negative effects:

* it increases tile requests
* it likely causes text/labels and POI markers embedded in the tiles to become smaller and unreadable
* it decreases the effective maximum zoom by 1

Therefore, carefully consider whether emulating retina mode is appropriate for your application, and disable it if necessary. Always prefer native retina tiles if they are available.

</details>
{% endstep %}

{% step %}
### Set the maximum zoom level covered by your tiles

Set the `maxNativeZoom` parameter to the maximum zoom level covered by your tile source. This will make flutter\_map scale the tiles at this level when zooming in further, instead of attempting to load new tiles at the higher zoom level (which will fail).

You can also set `MapOptions.maxZoom`, which is an absolute zoom limit for users. It is recommended to set this to a few levels greater than the maximum zoom level covered by any of your tile layers.
{% endstep %}

{% step %}
### Add caching

Caching makes your app faster and cheaper! Some tile servers, such as the OpenStreetMap tile server, will require you to use caching.

{% hint style="info" %}
The flutter\_map team is looking into implementing automatic caching into the core in the near-future. However, at the current time, you will need to add caching yourself.
{% endhint %}

There's multiple good options to add caching. See [#caching](../../tile-servers/offline-mapping.md#caching "mention") for more information.
{% endstep %}
{% endstepper %}

## Other Properties

### `panBuffer`

To make a more seamless experience, tiles outside the current viewable area can be 'preloaded', with the aim of minimizing the amount of non-tile space a user sees.

`panBuffer` sets the number of surrounding rows and columns around the viewable tiles that should be loaded, and defaults to 1.

{% hint style="warning" %}
Specifying a `panBuffer` too high may result in slower tile requests for all tiles (including those that are visible), and a higher load on the tile server. The effect is amplified on larger map dimensions/screen sizes.
{% endhint %}

### Tile Update Transformers

{% hint style="info" %}
`TileUpdateTransformer`(`s`) is a power-user feature. Most applications won't require it.
{% endhint %}

A `TileUpdateTransformer` restricts and limits `TileUpdateEvent`s (which are emitted 'by' `MapEvent`s), which cause tiles to update.

For example, a transformer can delay (throttle or debounce) updates through one of the built-in transformers, or pause updates during an animation, or force updates even when a `MapEvent` wasn't emitted.

For more information, see:

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/TileUpdateTransformer.html" %}
