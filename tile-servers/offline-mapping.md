# Offline Mapping

Using maps without an Internet connection is common requirement. Luckily, there are a few options available to you to implement offline mapping in your app.

* [Caching](offline-mapping.md#caching)\
  Automatically store tiles as the user loads them through interacting with the map, usually on a temporary basis
* [Bulk downloading](offline-mapping.md#bulk-downloading)\
  Download an entire area/region of tiles in one shot, ready for a known no-Internet situation
* [Bundling](offline-mapping.md#bundled-map-tiles)\
  Provide a set of pre-determined tiles to all users through app assets or the filesystem

## Caching

{% hint style="info" %}
flutter\_map only provides caching in-memory. All cached tiles will be cleared after the app session is ended.

The flutter\_map team is looking into implementing automatic caching into the core in the near-future. However, at the current time, you will need to add caching yourself.
{% endhint %}

Caching is used usually to improve user experience by reducing network waiting times, not necessarily to prepare for no-Internet situations. Caching can be more temporary (eg. in-memory/session-only, where the cache is cleared after the app is closed), or more long-term (eg. app cache, where the OS takes responsibility for clearing the app cache when necessary/when requested).

Many tile servers, such as the OpenStreetMap tile server, will require you to implement longer-term caching!

There's 3 methods that basic caching can be implemented in your app, two of which rely on community maintained plugins:

1. [flutter\_map\_cache](https://github.com/josxha/flutter_map_cache) (lightweight and MIT licensed)\
   &#xNAN;_&#x52;ecommended for projects that want plug-and-play simple long-term caching_
2. Custom implementation
   1. using a caching HTTP client passed to `NetworkTileProvider.httpClient` (using a package such as [http\_cache\_client](https://pub.dev/packages/http_cache_client))\
      &#xNAN;_&#x52;ecommended for projects that might already be using a caching HTTP client elsewhere and want to minimize dependencies_
   2. using a [custom `TileProvider`](../plugins/making-a-plugin/creating-new-tile-providers.md) with a caching `ImageProvider` (either custom or using a package such as [cached\_network\_image](https://pub.dev/packages/cached_network_image))
3. [flutter\_map\_tile\_caching](https://github.com/JaffaKetchup/flutter_map_tile_caching)\
   &#xNAN;_&#x52;ecommended for projects that want advanced caching and potentially_ [#bulk-downloading](offline-mapping.md#bulk-downloading "mention")_, but GPL licensed_

## Bulk Downloading

{% hint style="warning" %}
You must comply with the appropriate restrictions and terms of service set by your tile server. Always read the ToS before using a tile server. Failure to do so may lead to any punishment, at the tile server's discretion. Many tile servers will forbid or restrict bulk downloading, as it places additional strain on their servers.
{% endhint %}

Bulk downloading is used to prepare for known no-Internet situations by downloading map tiles, then serving these from local storage.

Bulk downloading is more complex than [#caching](offline-mapping.md#caching "mention"), especially for regions that are a non-rectangular shape. Implementing this can be very time consuming and prone to issues.

The [community maintained plugin 'flutter\_map\_tile\_caching'](https://github.com/JaffaKetchup/flutter_map_tile_caching) includes advanced bulk downloading functionality, of multiple different region shapes, and other functionality. It is however GPL licensed. To help choose whether FMTC or DIY is more appropriate for your use case, please see:

{% embed url="https://fmtc.jaffaketchup.dev/is-fmtc-right-for-me" %}

## Bundled Map Tiles

If you have a set of custom raster tiles that you need to provide to all your users, you may want to consider bundling them together, to make a them easier to deploy to your users. Bundles can be provided in two formats.

### Contained

Container formats, such as the traditional MBTiles, or the more recent PMTiles, store tiles usually in a database or binary internal format.

These require a special parser to read on demand, usually provided as a `TileProvider` by a plugin. The following community-maintained plugins are available to read these formats:

* [MBTiles](https://wiki.openstreetmap.org/wiki/MBTiles): [flutter\_map\_mbtiles](https://github.com/josxha/flutter_map_plugins/tree/main/flutter_map_mbtiles) ([vector\_map\_tiles\_mbtiles ](https://github.com/josxha/flutter_map_plugins/tree/main/vector_map_tiles_mbtiles)when using vector tiles)
* [PMTiles](https://github.com/protomaps/PMTiles): [flutter\_map\_pmtiles](https://github.com/josxha/flutter_map_plugins/tree/main/flutter_map_pmtiles) ([vector\_map\_tiles\_pmtiles](https://github.com/josxha/flutter_map_plugins/tree/main/vector_map_tiles_pmtiles) when using vector tiles, also works in online contexts)

### Uncontained

When uncontained, tiles are usually in a tree structure formed by directories, usually 'zoom/x/y.png'. These don't require special parsing, and can be provided directly to the `TileLayer` using one of the built-in local `TileProvider`s.

#### `AssetTileProvider`

You can ship an entire tile tree as part of your application bundle, and register it as assets in your app's pubspec.yaml.

This means that they will be downloaded together with your application, keeping setup simple, but at the expense of a larger application bundle size.

{% hint style="warning" %}
If using `AssetTileProvider`, every sub-directory of the tree must be listed seperately. See the example application's 'pubspec.yaml' for an example.
{% endhint %}

#### `FileTileProvider`

This allows for more flexibility: you could store a tile tree on a remote server, then download the entire tree later to the device's filesystem, perhaps after intial setup, or just an area that the user has selected.

This means that the setup may be more complicated for users, and it introduces a potentially long-running blocking action, but the application's bundle size will be much smaller.
