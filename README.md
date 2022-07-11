---
description: >-
  Mapping package for Flutter, based off of 'leaflet.js'. Simple and easy to
  learn, yet completely customizable and configurable, it's the best choice for
  mapping in your Flutter app.
cover: >-
  https://images.unsplash.com/photo-1478860409698-8707f313ee8b?crop=entropy&cs=tinysrgb&fm=jpg&ixid=MnwxOTcwMjR8MHwxfHNlYXJjaHwzfHxtYXB8ZW58MHx8fHwxNjU1MjMxMzY5&ixlib=rb-1.2.1&q=80
coverY: 0
---

# flutter\_map

[![Pub.dev](https://img.shields.io/pub/v/flutter\_map.svg?label=Latest+Version)](https://pub.dev/packages/flutter\_map) [![Checks & Tests](https://badgen.net/github/checks/fleaflet/flutter\_map?label=Checks+%26+Tests\&color=orange)](https://github.com/fleaflet/flutter\_map/actions?query=branch%3Amaster) [![points](https://badges.bar/flutter\_map/pub%20points)](https://pub.dev/packages/flutter\_map/score)\
[![stars](https://badgen.net/github/stars/fleaflet/flutter\_map?label=stars\&color=green\&icon=github)](https://github.com/fleaflet/flutter\_map/stargazers) [![likes](https://badges.bar/flutter\_map/likes)](https://pub.dev/packages/flutter\_map/score)      [![Open Issues](https://badgen.net/github/open-issues/fleaflet/flutter\_map?label=Open+Issues\&color=green)](https://github.com/fleaflet/flutter\_map/issues) [![Open PRs](https://badgen.net/github/open-prs/fleaflet/flutter\_map?label=Open+PRs\&color=green)](https://github.com/fleaflet/flutter\_map/pulls)

## Demonstration

This code snippet demonstrates everything you need for a simple map:

```dart
return FlutterMap(
    options: MapOptions(
        center: LatLng(51.509364, -0.128928),
        zoom: 9.2,
    ),
    layers: [
        TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
        ),
    ],
    nonRotatedChildren: [
        AttributionWidget.defaultWidget(
            source: 'OpenStreetMap contributors',
            onSourceTapped: null,
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

Vector tile support is not built in, but it is supported in beta by a plugin! See the full [Plugins List](plugins/list.md) for more information.

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

See the full [Plugins List](plugins/list.md) for more information.

</details>

<details>

<summary>Supports Markers, Polygons, and Polylines Properly</summary>

... and none of that complicated, confusing setup you need with the Google Maps package either. Just needs a normal widget builder or some coordinates, and nothing else.

Using these is simple and quick, and the power of Flutter's `StreamBuilder` can make all of these a truly dynamic solution.

</details>

## Support & Contact

Having trouble with 'flutter\_map', or have any suggestions? We hope we can help get you sorted as soon as possible.

The preferred way to get help with smaller issues and get recommendations is the official Discord server! Join today using the link: [https://discord.gg/egEGeByf4q](https://discord.gg/egEGeByf4q).

Alternatively, for bigger issues, suspected bugs, or feature requests, visit the [GitHub Issue Tracker](https://github.com/fleaflet/flutter\_map/issues) and ask away! We'll try to get back to you relatively quickly, but it may take longer for larger issues. Note that feature requests currently have a long wait time, so we'd love your contributions!

Additionally, please use the ratings system at the bottom of each page, so that we can improve lacking pages, or look to better rated pages for inspiration!
