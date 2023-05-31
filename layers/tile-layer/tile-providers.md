# Tile Providers

The `tileProvider` parameter in `TileLayer` takes a `TileProvider` object specifying a [tile provider](../../explanation/#tile-providers) to use for that layer.

This has a default of `NetworkTileProvider` which gets tiles from the internet through a dedicated image provider.

There's two situations in which you'll need to change the tile provider:

* Sourcing tiles from the filesystem or asset store: [#local-tile-providers](tile-providers.md#local-tile-providers "mention")
* Using a [plugin](../../plugins/list.md) that instructs you to do so ([creating-new-tile-providers.md](../../plugins/making-a-plugin/creating-new-tile-providers.md "mention"))

## Network Tile Provider

`NetworkTileProvider` takes two arguments, but you'll usually never need to specify them:

* `httpClient`: custom `BaseClient`\
  By default, a `RetryClient` backed by a standard `Client` is used
* `headers`: custom `Map<String, String>`\
  By default, only the default headers, plus a custom 'User-Agent' header based on the [#useragentpackagename](./#useragentpackagename "mention") property, are included with each request

## Local Tile Providers

These tile providers use the `templateUrl` to get the appropriate tile from the asset store of the application, or from a file on the users device, respectively.

{% hint style="warning" %}
Specifying any `fallbackUrl` (even if it is not used) in the `TileLayer` will reduce the performance of these providers.

It will cause [23% slower asset tile requests](https://github.com/fleaflet/flutter\_map/issues/1436#issuecomment-1569663004) with `AssetTileProvider`,  and will cause main thread blocking when requesting tiles from `FileTileProvider`.
{% endhint %}

### `AssetTileProvider()`

This tile providers uses the `templateUrl` to get the appropriate tile from the asset store of the application.

### `FileTileProvider()`

This tile providers uses the `templateUrl` to get the appropriate tile from the a path/directory/file on the user's device - either internal application storage or external storage.

{% hint style="warning" %}
On the web, `FileTileProvider()` will throw an `UnsupportedError` when a tile request is attempted, due to the lack of the web platform's access to the local filesystem.

If you know you are running on the web platform, use a [`NetworkTileProvider`](tile-providers.md#network-tile-provider) or a custom tile provider.
{% endhint %}

## Offline Mapping

{% content-ref url="../../tile-servers/offline-mapping.md" %}
[offline-mapping.md](../../tile-servers/offline-mapping.md)
{% endcontent-ref %}
