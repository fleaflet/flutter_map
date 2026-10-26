# Tile Providers

A `TileProvider` works with a `TileLayer` to supply tiles (usually images) when given tile coordinates.

Tile providers may support compatible [caching providers](caching.md) (including built-in caching), or may implement caching themselves.

Tiles are usually dynamically requested from the network/Internet, using the default `NetworkTileProvider`. Tiles can also come from the app's assets, the filesystem, a container/bundle, or any other source.

## `NetworkTileProvider`

This tile provider uses the `TileLayer.urlTemplate` to get the appropriate tile from the a network, usually the Internet.

{% hint style="warning" %}
Specifying any `fallbackUrl` (even if it is not used) in the `TileLayer` will prevent loaded tiles from being cached in memory.

This is to avoid issues where the `urlTemplate` is flaky (sometimes works, sometimes doesn't), to prevent potentially different tilesets being displayed at the same time.
{% endhint %}

For more information, check the API documentation.

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
