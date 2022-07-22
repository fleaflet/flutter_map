---
description: ... and Offline Mapping
---

# Tile Providers

The `tileProvider` parameter in `TileLayerOptions` takes a `TileProvider` object specifying a [tile provider](../../../getting-started/explanation/#tile-providers) to use for that layer.

This has a default of `NetworkNoRetryTileProvider`, which is recommended for most setups for better performance, unless your tile server is especially unreliable, or you need a local tile provider.

Custom `TileProvider`s can be implemented by your application or other libraries. These may not conform to the usual rules above, and may additionally have their own parameters.

## Network Tile Providers

Network tile providers can take a `Map<String, String>` of custom headers. Note that the [user agent](tile-providers.md#package-name-useragentpackagename) that is automatically generated will not override any 'User-Agent' header if specified here. On the web, the 'User-Agent' header is not sent, as the browser controls the user agent.

Whilst not on the web, network tile providers can take a custom `HttpClient`/`RetryClient`, if you need to use it for whatever reason.

### `NetworkNoRetryTileProvider()`&#x20;

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

On the web, `FileTileProvider()` will automatically use `NetworkImage()` behind the scenes. This is not recommended. If you know you are running on the web platform, avoid using this tile provider.

## Offline Mapping

### Bundled Map Tiles

If you have a set of custom raster tiles that you need to provide to all your users, you may want to consider bundling them together, to make a them easier to deploy to your users. Note that this is different to the [Caching](tile-providers.md#caching) section below.

There is essentially two options for doing this:

* Using `AssetTileProvider`, you can bundle a set of map tiles and register them as an asset within your app's pubspec.yaml. This means that they will be downloaded together with your application, keeping setup simple, but at the expense of a larger application bundle size.
* Using `FileTileProvider`, you can bundle a set of map tiles and store them on a remote web server, that can be downloaded from later. This means that the setup may be more complicated for users, but the application's bundle size will be much smaller.

Either way, the filesystem should be structured like this: 'offlineMap/{z}/{x}/{y}.png', where every .png image is a tile.

If you have a raster-format .mbtiles file, for example from TileMill, you should use [mbtilesToPngs](https://github.com/alfanhui/mbtilesToPngs) to convert it to the correct structure first. Alternatively, you can use an external package such as '[flutter\_mbtiles\_extractor](https://pub.dev/packages/flutter\_mbtiles\_extractor)' to extract during runtime.

### Caching

Solutions for better, more reliable, dynamic caching can either be built yourself using other packages (such as '[cached\_network\_image](https://pub.dev/packages/cached\_network\_image)'), or by using an existing [community maintained plugin (`flutter_map_tile_caching`)](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching) which handles caching and statistics for you, as well as offering methods to bulk download areas of maps.

If you prefer to offer a set of map tiles to all your users before runtime, consider using the [Offline Maps](tile-providers.md#undefined) solution instead.
