# Offline Mapping

Using maps without an Internet connection is common requirement. Luckily, there are a few options available to you to implement offline mapping in your app.

* [Caching](offline-mapping.md#caching-and-bulk-downloading)\
  Automatically store tiles as the user loads them through interacting with the map
* [Bulk downloading](offline-mapping.md#caching-and-bulk-downloading)\
  Download an entire area/region of tiles in one shot, ready for a known no-Internet situation
* [Bundling](offline-mapping.md#bundled-map-tiles)\
  Provide a set of tiles to all users through assets or the filesystem

## Caching & Bulk Downloading

The [community maintained plugin 'flutter\_map\_tile\_caching'](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching) aims to solve the first two points. FMTC is designed to be easy to implement, but also sufficiently advanced to cover most (if not all) use cases.

However, using simpler packages in a DIY solution can be a better option in some cases. You'll need to implement a custom `TileProvider` backed by an alternative image provider or cache lookup system: see [creating-new-tile-providers.md](../plugins/making-a-plugin/creating-new-tile-providers.md "mention").

To help choose whether FMTC or DIY is more appropriate for your use case, please see:

{% embed url="https://fmtc.jaffaketchup.dev/is-fmtc-right-for-me" %}

## Bundled Map Tiles

If you have a set of custom raster tiles that you need to provide to all your users, you may want to consider bundling them together, to make a them easier to deploy to your users.

There is essentially two options for doing this:

* Using `AssetTileProvider`, you can bundle a set of map tiles and register them as an asset within your app's pubspec.yaml. This means that they will be downloaded together with your application, keeping setup simple, but at the expense of a larger application bundle size.
* Using `FileTileProvider`, you can bundle a set of map tiles and store them on a remote web server, that can be downloaded from later. This means that the setup may be more complicated for users, but the application's bundle size will be much smaller.

Either way, the filesystem should be structured like this: 'offlineMap/{z}/{x}/{y}.png', where every .png image is a tile.

If you have a raster-format .mbtiles file, for example from TileMill, you should use [mbtilesToPngs](https://github.com/alfanhui/mbtilesToPngs) to convert it to the correct structure first. Alternatively, you can use an external package such as '[flutter\_mbtiles\_extractor](https://pub.dev/packages/flutter\_mbtiles\_extractor)' to extract during runtime.
