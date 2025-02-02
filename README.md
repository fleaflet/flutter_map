---
description: >-
  A versatile mapping package for Flutter. Simple and easy to learn, yet
  completely customizable and configurable, it's the best choice for mapping in
  your Flutter app.
cover: .gitbook/assets/Cover.jpg
coverY: -35
---

# flutter\_map

[![pub.dev](https://img.shields.io/pub/v/flutter_map.svg?label=Latest+Version)](https://pub.dev/packages/flutter_map) [![stars](https://badgen.net/github/stars/fleaflet/flutter_map?label=stars\&color=green\&icon=github)](https://github.com/fleaflet/flutter_map/stargazers) [![likes](https://img.shields.io/pub/likes/flutter_map?logo=flutter)](https://pub.dev/packages/flutter_map/score)        [![codecov](https://codecov.io/gh/fleaflet/flutter_map/graph/badge.svg?token=LgYgZQ0Yjj)](https://codecov.io/gh/fleaflet/flutter_map) [![Open Issues](https://badgen.net/github/open-issues/fleaflet/flutter_map?label=Open+Issues\&color=green)](https://github.com/fleaflet/flutter_map/issues) [![Open PRs](https://badgen.net/github/open-prs/fleaflet/flutter_map?label=Open+PRs\&color=green)](https://github.com/fleaflet/flutter_map/pulls)

{% hint style="success" %}
Welcome to v8! Find out [new-in-v8.md](getting-started/new-in-v8.md "mention"), or if you're new here, check out the [#code-demo](./#code-demo "mention") & [installation.md](getting-started/installation.md "mention") instructions to get started.&#x20;

v7 documentation is still available: [v7](https://app.gitbook.com/o/1aKKbSpe255wyVNDoFYc/s/O2hE9FJb0PVZ0w3qEsM8/ "mention"). Some plugins may require some time to update to support v8.
{% endhint %}

## Why & How?

See why you should use flutter\_map for your project, and see how you can use flutter\_map for your project. It's a great idea and takes no more time than other libraries!

{% content-ref url="why-and-how/choose.md" %}
[choose.md](why-and-how/choose.md)
{% endcontent-ref %}

{% content-ref url="why-and-how/how-does-it-work/" %}
[how-does-it-work](why-and-how/how-does-it-work/)
{% endcontent-ref %}

{% content-ref url="why-and-how/demo-and-examples.md" %}
[demo-and-examples.md](why-and-how/demo-and-examples.md)
{% endcontent-ref %}

## Code Demo

Setting up an interactive and compliant[^1] map is simpler than making your lunch-time coffee! It can be accomplished in just under 30 lines and a minute or two to install.

This code snippet demonstrates **everything** you need for a simple map (in under 30 lines!), but of course, FM is capable of much more than just this, and you could find yourself lost in the many options available and possibilities opened!

{% code lineNumbers="true" fullWidth="true" %}
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

@override
Widget build(BuildContext context) {
  return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(51.509364, -0.128928), // Center the map over London
      initialZoom: 9.2,
    ),
    children: [
      TileLayer( // Bring your own tiles
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
        userAgentPackageName: 'com.example.app', // Add your app identifier
        // And many more recommended properties!
      ),
      RichAttributionWidget( // Include a stylish prebuilt attribution widget that meets all requirments
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
          ),
          // Also add images...
        ],
      ),
    ],
  );
}
```
{% endcode %}

## Get Help

Not quite sure about something? No worries, we're here to help!

* Check the [#faqs](./#faqs "mention") below, and double check the documentation
* Then, for bug reports & feature requests: check for previous issues, then ask in [GitHub Issues](https://github.com/fleaflet/flutter_map/issues)
* Then, for support & everything else: ask in [flutter\_map Discord server](https://discord.gg/BwpEsjqMAH) or [GitHub Discussions](https://github.com/fleaflet/flutter_map/discussions)

{% hint style="info" %}
We're a community maintained project and the maintainers would greatly appreciate any help in implementing features and fixing bugs! Feel free to jump in: [https://github.com/fleaflet/flutter\_map/blob/master/CONTRIBUTING.md](https://github.com/fleaflet/flutter_map/blob/master/CONTRIBUTING.md).

Please remember that we are volunteers and cannot guarantee support. The standard Code of Conduct is here to keep our community a safe and friendly place for everyone: [https://github.com/fleaflet/flutter\_map/blob/master/CODE\_OF\_CONDUCT.md](https://github.com/fleaflet/flutter_map/blob/master/CODE_OF_CONDUCT.md).
{% endhint %}

### FAQs

We get quite a lot of similar questions, so please check if your question is here before you ask!

{% content-ref url="why-and-how/how-does-it-work/" %}
[how-does-it-work](why-and-how/how-does-it-work/)
{% endcontent-ref %}

<details>

<summary>How can I use a custom map style?<br>How can I prevent POI/labels rotating when the map rotates?<br>How can I remove certain POI/labels from the map?</summary>

Unfortunately, this library cannot change the tiles you give it: it has no control over the tiles displayed in the `TileLayer`. This is a limitation of the technology, not this library.

This is because raster tiles are just images generated by a 3rd party tile server (dictated by your URL template), and therefore cannot be changed by the library that displays the tiles. Filters can be applied to the entire tile, such as an emulated dark mode, but these effects do not look great.

However, tilesets can be styled. This is the most effective way of using custom styles. These methods may help you with this:&#x20;

* You may wish to use a commercial service like Mapbox Studio, which allows you to style multiple tilesets. See [using-mapbox.md](tile-servers/using-mapbox.md "mention").
* Alternatively, you can experiment with vector tiles. These are not pre-rendered, and so allow any style you desire to be applied on the fly. See [#vector-tiles](why-and-how/how-does-it-work/raster-vs-vector-tiles.md#vector-tiles "mention").
* Your last option is to serve tiles yourself. See [other-options.md](tile-servers/other-options.md "mention").

</details>

<details>

<summary>How can I route a user between two locations?<br>Why does the <code>Polyline</code> only go in a straight line between two points?</summary>

See [#routing-navigation](layers/polyline-layer.md#routing-navigation "mention").

</details>

<details>

<summary>How can I add a <code>Marker</code> where the user's location is?<br>How can I center the map on the user's location?</summary>

This is beyond the scope of flutter\_map. However, you can use the [community maintained plugin 'flutter\_map\_location\_marker'](https://github.com/tlserver/flutter_map_location_marker) to do this.

Alternatively, use the 'location' and 'compass' packages to generate a stream of the user's location and heading, and feed that to a `Marker` using a `StreamBuilder`.

</details>

<details>

<summary>Why don't any map tiles appear?</summary>

If no tiles are appearing (if tiles are appearing on some zoom levels but not others, see below), try performing the following debugging steps:

1. Is the `templateUrl` or WMS configuration correct (to the best of your knowledge)?
2. Have you followed the platform specific setup ([#additional-setup](getting-started/installation.md#additional-setup "mention")) instructions (if applicable for your platform)?
3. Check the Network tab either in Flutter DevTools or the browser DevTools to see why/if the tile requests are failing.
4. If none of those solved the issue, check if there are any widgets covering the map, or any errors in the console (particularly in release mode)?

</details>

<details>

<summary>Why does the map disappear/go grey when I zoom in far?<br>Why does the map stop zooming in even though I know there are more zoom levels?</summary>

If tiles are disappearing when you zoom in, the default grey background of the `FlutterMap` widget will shine through. This usually means that the tile server doesn't support these higher zoom levels.

If you know that there are more tiles available further zoomed in, but flutter\_map isn't showing them and scaling a particular zoom level instead, it's likely because the `TileLayer.maxNativeZoom` property is set too low (it defaults to 19).

To set/change the zoom level at which FM starts scaling tiles, change the `TileLayer.maxNativeZoom` property. To set/change the max zoom level that can actually be zoomed to (hard limit), use `MapOptions.maxZoom`.

</details>

<details>

<summary>How can I make the map 3D, or view it as a globe?</summary>

Unfortunately, this isn't supported, partially due to lack of time on the maintainer's part to implement this feature, partially due to technical limitations. PRs are welcome!

</details>

[^1]: (includes necessary attribution)
