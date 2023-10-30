# Offline Mapping

Using maps without an Internet connection is common requirement. Luckily, there are a few options available to you to implement offline mapping in your app.

* [Caching](offline-mapping.md#caching)\
  Automatically store tiles as the user loads them through interacting with the map
* [Bulk downloading](offline-mapping.md#bulk-downloading)\
  Download an entire area/region of tiles in one shot, ready for a known no-Internet situation
* [Bundling](offline-mapping.md#bundled-map-tiles)\
  Provide a set of tiles to all users through assets or the filesystem

## Caching

There's 3 methods that basic caching can be implemented in your app, two of which rely on community maintained plugins:

1. [flutter\_map\_cache](https://github.com/josxha/flutter\_map\_cache) (lightweight and MIT licensed)
2. [flutter\_map\_tile\_caching](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching) (also includes [#bulk-downloading](offline-mapping.md#bulk-downloading "mention"), but GPL licensed)
3. Custom implementation, via a [custom `TileProvider`](../plugins/making-a-plugin/creating-new-tile-providers.md) and `ImageProvider` (either custom or via a package such as [cached\_network\_image](https://pub.dev/packages/cached\_network\_image))

## Bulk Downloading

When it comes to bulk downloading, this is much more complex than [#caching](offline-mapping.md#caching "mention"), especially for regions that are a non-rectangular shape. Implementing this can be very time consuming and prone to issues.

The [community maintained plugin 'flutter\_map\_tile\_caching'](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching) includes advanced bulk downloading functionality, of multiple different region shapes, and other functionality. It is however GPL licensed. To help choose whether FMTC or DIY is more appropriate for your use case, please see:

{% embed url="https://fmtc.jaffaketchup.dev/is-fmtc-right-for-me" %}

## Bundled Map Tiles

If you have a set of custom raster tiles that you need to provide to all your users, you may want to consider bundling them together, to make a them easier to deploy to your users.

There is essentially two options for doing this:

* Using `AssetTileProvider`, you can bundle a set of map tiles and register them as an asset within your app's pubspec.yaml. This means that they will be downloaded together with your application, keeping setup simple, but at the expense of a larger application bundle size.
* Using `FileTileProvider`, you can bundle a set of map tiles and store them on a remote web server, that can be downloaded from later. This means that the setup may be more complicated for users, but the application's bundle size will be much smaller.

Either way, the filesystem should be structured like this: 'offlineMap/{z}/{x}/{y}.png', where every .png image is a tile.

If you have a raster-format .mbtiles file, for example from TileMill, you should use [mbtilesToPngs](https://github.com/alfanhui/mbtilesToPngs) to convert it to the correct structure first. Alternatively, you can use an external package such as '[flutter\_mbtiles\_extractor](https://pub.dev/packages/flutter\_mbtiles\_extractor)' to extract during runtime.
