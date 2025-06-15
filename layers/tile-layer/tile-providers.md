# Tile Providers

A `TileProvider` works with a `TileLayer` to supply tiles (usually images) when given tile coordinates.

Tile providers may support compatible [caching providers](caching.md) (including built-in caching), or may implement caching themselves.

Tiles are usually dynamically requested from the network/Internet, using the default `NetworkTileProvider`. Tiles can also come from the app's assets, the filesystem, a container/bundle, or any other source.

## Network Tile Providers

These tile providers use the `TileLayer.urlTemplate` to get the appropriate tile from the a network, usually the Internet.

The underlying custom `ImageProvider`s will cache tiles in memory, so that they do not require another request to the tile server if they are pruned then re-loaded. This should result in them being loaded quicker, as well as enabling already loaded tiles to appear even without Internet connection (at least in the same session).

{% hint style="warning" %}
Specifying any `fallbackUrl` (even if it is not used) in the `TileLayer` will prevent loaded tiles from being cached in memory.

This is to avoid issues where the `urlTemplate` is flaky (sometimes works, sometimes doesn't), to prevent potentially different tilesets being displayed at the same time.
{% endhint %}

### `NetworkTileProvider`

This is the default tile provider, and does nothing particularly special. It takes two arguments, but you'll usually never need to specify them:

* `httpClient`: `BaseClient`\
  By default, a `RetryClient` backed by a standard `Client` is used
* `headers`: `Map<String, String>`\
  By default, only headers sent by the platform are included with each request, plus an overridden (where possible) 'User-Agent' header based on the [#useragentpackagename](./#useragentpackagename "mention") property

### [`CancellableNetworkTileProvider`](https://github.com/fleaflet/flutter_map_cancellable_tile_provider)

{% hint style="info" %}
This requires the '[flutter\_map\_cancellable\_tile\_provider](https://github.com/fleaflet/flutter_map_cancellable_tile_provider)' plugin to be installed.

This plugin is part of the official 'flutter\_map' organisation, and maintained by the same maintainers.
{% endhint %}

Tiles that are removed/pruned before they are fully loaded do not need to complete (down)loading, and therefore do not need to complete the HTTP interaction. Cancelling these unnecessary tile requests early could:

* Reduce tile loading durations (particularly on the web)
* Reduce users' (cellular) data and cache space consumption
* Reduce costly tile requests to tile servers\*
* Improve performance by reducing CPU and IO work

This provider uses '[dio](https://pub.dev/packages/dio)', which supports aborting unnecessary HTTP requests in-flight, after they have already been sent.

Although HTTP request abortion is supported on all platforms, it is especially useful on the web - and therefore recommended for web apps. This is because the web platform has a limited number of simulatous HTTP requests, and so closing the requests allows new requests to be made for new tiles.\
On other platforms, the other benefits may still occur, but may not be as visible as on the web.

Once HTTP request abortion is [added to Dart's 'native' 'http' package (which already has a PR opened)](https://github.com/dart-lang/http/issues/424), `NetworkTileProvider` will be updated to take advantage of it, replacing and deprecating this provider. This tile provider is currently a separate package and not the default due to the reliance on the additional Dio dependency.

## Local Tile Providers

These tile providers use the `urlTemplate` to get the appropriate tile from the asset store of the application, or from a file on the users device, respectively.

{% hint style="warning" %}
Specifying any `fallbackUrl` (even if it is not used) in the `TileLayer` will reduce the performance of these providers.

It will cause [23% slower asset tile requests](https://github.com/fleaflet/flutter_map/issues/1436#issuecomment-1569663004) with `AssetTileProvider`,  and will cause main thread blocking when requesting tiles from `FileTileProvider`.
{% endhint %}

### `AssetTileProvider`

This tile providers uses the `templateUrl` to get the appropriate tile from the asset store of the application.

{% hint style="info" %}
Asset management in Flutter leaves a lot to be desired! Unfortunately, every single sub-directory (to the level of tiles) must be listed.
{% endhint %}

### `FileTileProvider`

This tile providers uses the `templateUrl` to get the appropriate tile from the a path/directory/file on the user's device - either internal application storage or external storage.

{% hint style="warning" %}
On the web, `FileTileProvider()` will throw an `UnsupportedError` when a tile request is attempted, due to the lack of the web platform's access to the local filesystem.

If you know you are running on the web platform, use a [`NetworkTileProvider`](tile-providers.md#network-tile-provider) or a custom tile provider.
{% endhint %}

## Offline Mapping

{% content-ref url="../../tile-servers/offline-mapping.md" %}
[offline-mapping.md](../../tile-servers/offline-mapping.md)
{% endcontent-ref %}
