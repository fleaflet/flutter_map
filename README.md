---
description: >-
  Mapping package for Flutter, based off of 'leaflet.js'. Simple and easy to
  learn, yet completely customizable and configurable, it's the best choice for
  mapping in your Flutter app.
cover: >-
  https://3967342857-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FYFI6k92MXbd87FM5cPCk%2Fuploads%2FIkeWyssNqkcXDOHjw3Rn%2FOpenStreetMap%20Screenshot.jpg?alt=media&token=71bbb4f1-75f2-4938-99ca-c1e5af8f5477
coverY: -47.966226138032305
---

# flutter\_map

[![Pub.dev](https://camo.githubusercontent.com/a796d19cced2795c62dee9f3b165665449dbfd0bd46bf39beceef3371f14ebee/68747470733a2f2f696d672e736869656c64732e696f2f7075622f762f666c75747465725f6d61702e7376673f6c6162656c3d4c61746573742b56657273696f6e)](https://pub.dev/packages/flutter\_map) [![Checks & Tests](https://camo.githubusercontent.com/abc73df57e8cd43d4af75746819de7fca6a4d29986fa85168261451c91b03af4/68747470733a2f2f62616467656e2e6e65742f6769746875622f636865636b732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d436865636b732b2532362b546573747326636f6c6f723d6f72616e6765)](https://github.com/fleaflet/flutter\_map/actions?query=branch%3Amaster) [![points](https://camo.githubusercontent.com/2fe0cefb9f575203da4f29269b9d3a06c0b56b0abca74ba77082849f0f852e93/68747470733a2f2f696d672e736869656c64732e696f2f7075622f706f696e74732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score)\
[![stars](https://camo.githubusercontent.com/7e6d80df311cbd5e68edf6994e404a97af85c84f7ec66614875dba12f055c246/68747470733a2f2f62616467656e2e6e65742f6769746875622f73746172732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d737461727326636f6c6f723d677265656e2669636f6e3d676974687562)](https://github.com/fleaflet/flutter\_map/stargazers) [![likes](https://camo.githubusercontent.com/450afb6eb57ffb0e3cdae61f8a90d51541dbe09eaddcc69900cb09a91762363a/68747470733a2f2f696d672e736869656c64732e696f2f7075622f6c696b65732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score)      [![Open Issues](https://camo.githubusercontent.com/3f89334e961516c8b3eef4879a287818a2b8e6523e5f9f8d3767e1d98c8a4f44/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d6973737565732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b49737375657326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/issues) [![Open PRs](https://camo.githubusercontent.com/2d48f34537361cf13f775e8c88c5884a7a7b280469b319453b2ccdabdee1f2db/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d7072732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b50527326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/pulls)

## Demonstration

This code snippet demonstrates everything you need for a simple map:

```dart
return FlutterMap(
    options: MapOptions(
        center: LatLng(51.509364, -0.128928),
        zoom: 9.2,
    ),
    nonRotatedChildren: [
        AttributionWidget.defaultWidget(
            source: 'OpenStreetMap contributors',
            onSourceTapped: null,
        ),
    ],
    children: [
        TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
        ),
    ],
);
```

Choose an initial center and zoom (London in this case), add and credit a tile layer, and you're done!

Of course, this package has much more functionality than shown here, and these are described extensively throughout this documentation.

## Feature Highlights

<details>

<summary>Supports Any* Map Style</summary>

Through the `templateUrl` argument, you can add any raster tile server that supports WMTS. So you're not just limited to Google Maps or Mapbox anymore!

Through `WMSOptions`, you can use any WMS raster tile server, such as those provided by national governments and agencies.

If you have a local set of raster tiles, we support displaying those as well, with no complicated setup.

Vector tile support is not built in, but it is supported in beta by a plugin! See the full [list.md](plugins/list.md "mention") for more information.

</details>

<details>

<summary>Simple Setup</summary>

No need for 'flutter\_map' API keys or excessive platform-dependent specific setup. Just depend on it and set it up in less than 5 minutes. The snippet above really does work!

After that, you can add a map controller to programmatically control your map, such as position, zoom, and more.

</details>

<details>

<summary>Wide Ecosystem Of Plugins</summary>

Can't find what you need built in? There's probably a plugin for that!

From tracking the user's location to caching tiles for offline use, this is all supported by 3rd party plugins!

See the full [list.md](plugins/list.md "mention") for more information.

</details>

<details>

<summary>Supports Markers, Polygons, and Polylines Properly</summary>

... and has none of that complicated, confusing setup you need with the Google Maps package either. Just needs a normal widget builder or some coordinates, and nothing else.

Using these is simple and quick, and the power of Flutter's `StreamBuilder` can make all of these a truly dynamic solution.

</details>

## Support & Contact

Having trouble with 'flutter\_map', or have any suggestions? We hope we can help get you sorted as soon as possible.

The preferred way to get help with smaller issues and get recommendations is the official Discord server! Join today using the link: [https://discord.gg/egEGeByf4q](https://discord.gg/egEGeByf4q).

Alternatively, for bigger issues, suspected bugs, or feature requests, visit the [GitHub Issue Tracker](https://github.com/fleaflet/flutter\_map/issues) and ask away! We'll try to get back to you relatively quickly, but it may take longer for larger issues. Note that feature requests currently have a long wait time, so we'd love your contributions!

Additionally, please use the ratings system at the bottom of each page, so that we can improve lacking pages, or look to better rated pages for inspiration!
