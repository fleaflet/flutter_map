---
description: >-
  Flutter's №1 non-commercially aimed map client: it's easy-to-use, versatile,
  vendor-free, fully cross-platform, and 100% pure-Flutter
cover: .gitbook/assets/Main Hero.png
coverY: 0
layout:
  cover:
    visible: true
    size: full
  title:
    visible: true
  description:
    visible: true
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# flutter\_map

{% hint style="success" %}
Welcome to v8! Find out [new-in-v8.md](getting-started/new-in-v8.md "mention"), or if you're new here, check out the [#code-demo](./#code-demo "mention") & [installation.md](getting-started/installation.md "mention") instructions to get started.&#x20;

v7 documentation is still available: [v7](https://app.gitbook.com/o/1aKKbSpe255wyVNDoFYc/s/O2hE9FJb0PVZ0w3qEsM8/ "mention"). Some plugins may require some time to update to support v8.
{% endhint %}

| [![GitHub source](https://gist.github.com/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/github.svg)](https://github.com/fleaflet/flutter_map) [![pub.dev package](https://gist.github.com/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/download.svg)](https://pub.dev/packages/flutter_map)    [![Join our Discord](https://gist.github.com/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/discord.svg)](https://discord.gg/BwpEsjqMAH) [![Support us](https://gist.github.com/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/github_sponsor.svg)](https://github.com/sponsors/fleaflet) |
| :-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |

{% embed url="https://demo.fleaflet.dev" %}

## Why choose flutter\_map?

<table data-card-size="large" data-view="cards" data-full-width="false"><thead><tr><th align="center"></th><th align="center"></th></tr></thead><tbody><tr><td align="center">🗺️ <strong>No more vendor lock-in: better flexibility, quality, and price</strong></td><td align="center"><p>We natively support any static <a data-footnote-ref href="#user-content-fn-1">raster*</a> tiles! <strong>Bring your own tiles</strong> from your own server, the user's device, a tile container, or another externally-operated tile server. Use any service, but always be free to change to get the best fit, quality, and price.<br></p><p>Still want to use those familiar maps? Consider great quality and better priced alternatives, or use the more mainstream Google Maps or Mapbox Maps with flutter_map<a data-footnote-ref href="#user-content-fn-2">*</a>.</p></td></tr><tr><td align="center">🚀 <strong>Stress-free setup &#x26; easy-to-use</strong></td><td align="center">Migrating from a commercial library (such as Google Maps) has never been easier. No more complex platform-specific setup, no more buggy &#x26; limited platform views (we're 100% pure-Flutter), and no more lacking-documentation &#x26; support. Just setup a simple widget, grab a string from your tile server, and you're done! And, it'll work across all the platforms Flutter supports.<br><br>Check out our <a data-mention href="./#code-demo">#code-demo</a> to see just how simple it is.</td></tr><tr><td align="center">🧩 <strong>Customize and expand endlessly</strong></td><td align="center">Add interactive and highly customizable polygons, polylines, and markers (which support widget children) to your map easily and quickly. And because we're 100% Flutter, it's easy to add your own stuff on top without messing around in platform views.<br><br>A huge community of developers maintain an ecosystem of plugins for you to supercharge flutter_map with.</td></tr><tr><td align="center">👋 <strong>But don't just take it from us...</strong></td><td align="center">Hundreds of thousands of apps and users choose flutter_map for mapping in their Flutter app, making us Flutter's №1 non-commercially aimed map client on pub.dev.<br><br>Check out some independent reviews, comparisons, and studies, and see who's using flutter_map right now: <a data-mention href="why-and-how/showcase.md">showcase.md</a></td></tr></tbody></table>

{% content-ref url="why-and-how/showcase.md" %}
[showcase.md](why-and-how/showcase.md)
{% endcontent-ref %}

{% hint style="warning" %}
If you're looking for [vector tiles](why-and-how/how-does-it-work/raster-vs-vector-tiles.md#raster-tiles), we don't currently support them natively. We only support raster tiles at the moment.

However, [options are available](why-and-how/how-does-it-work/raster-vs-vector-tiles.md#using-vector-tiles), and the we and the community are actively exploring & developing future support!
{% endhint %}

## Code Demo

Setting up an interactive and compliant[^3] map is simpler than making your lunch-time coffee! It can be accomplished in just under 30 lines and a minute or two to install.

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

[^1]: See below for information about vector tile support.

[^2]: It may cost more to use services which provide their own SDKs through flutter\_map, but there's a reason they do that ;)

[^3]: (includes necessary attribution)
