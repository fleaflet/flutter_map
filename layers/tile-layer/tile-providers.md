# Tile Providers

The `tileProvider` parameter in `TileLayer` takes a `TileProvider` object specifying a [tile provider](../../explanation/#tile-providers) to use for that layer.

This has a default of `NetworkNoRetryTileProvider`, which is recommended for most setups for better performance, unless your tile server is especially unreliable, or you need a local tile provider.

Custom `TileProvider`s can be implemented by your application or other libraries. These may not conform to the usual rules above, and may additionally have their own parameters.

## Network Tile Providers

Network tile providers can take a `Map<String, String>` of custom headers. Note that the [user agent](tile-providers.md#package-name-useragentpackagename) that is automatically generated will not override any 'User-Agent' header if specified here. On the web, the 'User-Agent' header is not sent, as the browser controls the user agent.

Whilst not on the web, network tile providers can take a custom `HttpClient`/`RetryClient`, if you need to use it for whatever reason.

### `NetworkNoRetryTileProvider()`&#x20;

This is the default tile provider.

This tile provider uses the `templateUrl` to get the appropriate tile from the Internet, and it won't retry the request if it fails.

There is no guarantee about the default caching behaviour, but tiles should be cached until an application restart.

### `NetworkTileProvider()`

This tile provider uses the `templateUrl` to get the appropriate tile from the Internet, but it will retry the request as specified in the `RetryClient` (which can be customised as needed when not on the web).

There is no guarantee about the default caching behaviour, but tiles should be cached until an application restart.&#x20;

## Local Tile Providers

These tile providers use the `templateUrl` to get the appropriate tile from the asset store of the application, or from a file on the users device, respectively

### `AssetTileProvider()`

This tile providers uses the `templateUrl` to get the appropriate tile from the asset store of the application.

### `FileTileProvider()`

This tile providers uses the `templateUrl` to get the appropriate tile from the a path/directory/file on the user's device - either internal application storage or external storage.

{% hint style="warning" %}
On the web, `FileTileProvider()` will automatically use `NetworkImage()` behind the scenes. This is not recommended. If you know you are running on the web platform, avoid using this tile provider.
{% endhint %}

## Offline Mapping

{% content-ref url="../../tile-servers/offline-mapping.md" %}
[offline-mapping.md](../../tile-servers/offline-mapping.md)
{% endcontent-ref %}
