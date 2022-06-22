# Tile Layer

{% hint style="info" %}
This page only talks about WMTS-supporting raster layers, which is the most common and default type of mapping.

For information about WMS-supporting layers or vector tiles, visit the appropriate pages.
{% endhint %}

As explained in the [How Does It Work?](../../getting-started/explanation.md) page, tiles for a map in 'flutter\_map' are provided by tile providers that go inside of a `TileLayerOptions()`. That might look something like this:

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          tileProvider: NonCachingNetworkTileProvider(),
        ),
    ],
),
```

None of the properties are programmatically required, but the bare minimum required to display anything is `urlTemplate`.

Below are some of the main parameters you are likely to need, but there are more available from the API Reference.

## URL Template (`urlTemplate:`)

Takes a string that is a valid URL, which is the template to use when the tile provider constructs the URL to request a tile from a tile server. For example:

```dart
        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
```

will use the default OpenStreetMap tile server.

The '{s}', '{z}', '{x}' & '{y}' parts indicate where to place the subdomain, zoom level, x coordinate, and y coordinate respectively. Not providing at least the latter 3 parts won't necessarily throw an error, but the map won't show anything.

## Subdomains (`subdomains:`)

Takes a list of strings specifying the available subdomains to avoid rate limiting by the browser/engine. For example:

```dart
        subdomains: ['a', 'b', 'c'],
```

These are the available sub-subdomains for Open Street Maps' tile server, and one will be chosen differently every request by the tile provider to replace the '{s}' part of the `urlTemplate`.

If you are not sure of the correct values for your server, don't specify anything. For example, the `urlTemplate` used in the example above will work without the '{s}' part.

{% hint style="info" %}
There were two main reasons this option is provided:

* Leaflet.js relied on this to get around browser limitations on HTTP connections ([source - second paragraph](https://wiki.openstreetmap.org/wiki/Slippy\_map\_tilenames#Tile\_servers)), and because 'flutter\_map' is a close port of 'leaflet.js', it retains this feature.
* Large servers used to rely on this technique to load-balance, and some small or private servers still do.
{% endhint %}

## Tile Bounds (`tileBounds:`)

Takes a `LatLngBounds` to restrict the layer to only loading tiles within that area. For example:

```dart
        tileBounds: LatLngBounds(
            LatLng(32.2934590056236, 24.328924534719548),
            LatLng(21.792152188247265, 37.19854583903912),
        ),
```

will restrict the tiles to only loading Egypt (a square-ish country). Note that the map can still be moved freely outside of this range.

An example use-case might therefore be loading a specialised map for a region and just a basic map style elsewhere (different `urlTemplate`s). In this case, the bounded layer should go beneath the unbounded layer. Setting `backgroundColor: Colors.transparent` is also necessary on the bounded layer to ensure the other layer is visible elsewhere.

## Tile Provider (`tileProvider:`)

Takes a `TileProvider` object specifying a tile provider to use for that layer. Has a default.

Some tile providers will also take their own arguments.

The provided tile providers in 'flutter\_map' are ~~somewhat~~ very confusing in their naming and functionality, as their functionality has been tweaked over time without changing the names (to avoid breaking changes), so you can read below to see which suits your use-case. Note that you can write your own tile provider, or use a plugin which adds more tile providers.

### `NonCachingNetworkTileProvider()` (default)

This tile provider uses the `templateUrl` to get the appropriate tile from the Internet, and it won't retry the request if it fails.

It will only cache tiles in memory, so do not rely on it at all to cache past an app restart. It should cache tiles until an app restart, but there is no guarantee. The name is chosen to remind you that it should not be used for caching purposes.

### `NetworkTileProvider()`

This tile provider uses the `templateUrl` to get the appropriate tile from the Internet, but it will retry the request up to 3 times if it fails with HTTP Status Code '503 Temporary Failure'.

It will only cache tiles in memory, so do not rely on it at all to cache past an app restart. It should cache tiles until an app restart, but there is no guarantee.

### `AssetTileProvider()` and `FileTileProvider()`

These tile providers use the `templateUrl` to get the appropriate tile from the asset store of the app, or from a file on the users device, respectively. On the web, `FileTileProvider()` will automatically use `NetworkImage()` behind the scenes.

#### Offline Maps

The `AssetTileProvider` is particularly useful to provide a set of map tiles to all your users without having to download it after the application is installed. Note that this is different to the [Caching](tile-layer.md#caching) section below.

The filesystem should be structured like this: 'assets/offlineMap/{z}/{x}/{y}.png', where every png is a tile.&#x20;

If you have a raster-format .mbtiles file, for example from TileMill, you should use [mbtilesToPngs](https://github.com/alfanhui/mbtilesToPngs) to convert it to the correct structure.

### Caching

Whilst `FileTileProvider()` can be used for caching, better solutions can either be constructed yourself using other packages (such as [`cached_network_image`](https://pub.dev/packages/cached\_network\_image)), or by using an existing [community maintained plugin (`flutter_map_tile_caching`)](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching) which handles caching and statistics for you, as well as offering methods to bulk download areas of maps.

If you prefer to offer a set of map tiles to all your users before runtime, consider using the [Offline Maps](tile-layer.md#undefined) solution instead.
