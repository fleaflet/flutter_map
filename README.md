---
description: >-
  A versatile mapping package for Flutter. Simple and easy to learn, yet
  completely customizable and configurable, it's the best choice for mapping in
  your Flutter app.
cover: .gitbook/assets/Cover.jpg
coverY: -35
---

# flutter\_map

[![pub.dev](https://camo.githubusercontent.com/dcdb87d5d32ce7d0a83302ccccd6e5c70c55894e7c7920c6417b13761c8c773c/68747470733a2f2f696d672e736869656c64732e696f2f7075622f762f666c75747465725f6d61702e7376673f6c6162656c3d4c61746573742b56657273696f6e)](https://pub.dev/packages/flutter\_map) [![stars](https://camo.githubusercontent.com/e3069fba0ddc64303cf9a1a60be83b6f789cfee3b3b39c2c062e63cece4d26f7/68747470733a2f2f62616467656e2e6e65742f6769746875622f73746172732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d737461727326636f6c6f723d677265656e2669636f6e3d676974687562)](https://github.com/fleaflet/flutter\_map/stargazers) [![likes](https://camo.githubusercontent.com/102d04f1c16aad975caa6d413d84ab27b815a53910e72b41b81146b03b71f75a/68747470733a2f2f696d672e736869656c64732e696f2f7075622f6c696b65732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score)        [![codecov](https://camo.githubusercontent.com/2e49ab046582d625b4559b04b726e596f6f0492d9ed6aef49d7cea3a3c3036d7/68747470733a2f2f636f6465636f762e696f2f67682f666c6561666c65742f666c75747465725f6d61702f67726170682f62616467652e7376673f746f6b656e3d4c6759675a5130596a6a)](https://codecov.io/gh/fleaflet/flutter\_map) [![Open Issues](https://camo.githubusercontent.com/2237656d711e52f75b8c088f51236d5e2c910bd19d38131dc47aefe07a68c5af/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d6973737565732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b49737375657326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/issues?q=sort%3Aupdated-desc+is%3Aissue+is%3Aopen) [![Open PRs](https://camo.githubusercontent.com/30fb50b9f4b92e66c01fd6fce5fe3fb7dec5419de1492953772c635bb1ef2886/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d7072732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b50527326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/pulls?q=sort%3Aupdated-desc+is%3Apr+is%3Aopen)

## Feature Highlights

<table data-card-size="large" data-view="cards" data-full-width="true"><thead><tr><th align="center"></th><th align="center"></th><th data-hidden data-card-cover data-type="files"></th></tr></thead><tbody><tr><td align="center">🗺️ <strong>No more vendor lock-in</strong></td><td align="center">We natively support any static raster* tile server, including from a web server or even from the local file system or app asset store.<br>Use any service, or your own, but always be free to change!<br><em>*Vector tiles are supported with a community-maintained plugin.</em></td><td></td></tr><tr><td align="center">💪 <strong>Stress free setup &#x26; easy to use</strong></td><td align="center">Migrating from a commercial library (such as Google Maps) has never been easier! No more complex platform-specific setup, no more difficult API keys: just add a widget and you're done.<br>Our documentation and 3 layers of support are here to get your app using the best mapping library for Flutter.</td><td></td></tr><tr><td align="center">🧩 <strong>Wide ecosystem of plugins</strong></td><td align="center">In the event that flutter_map doesn't natively contain something you need, just check to see if there's a community maintained plugin that does what you need!</td><td></td></tr><tr><td align="center">➕ <strong>Customize and expand endlessly</strong></td><td align="center">Add interactive and highly customizable polygons, polylines, and markers (which support widget children) to your map easily and quickly. And because we're 100% Flutter, it's easy to add your own stuff on top without messing around in platform views.</td><td></td></tr></tbody></table>

{% hint style="success" %}
Don't just take it from us - we really are the best mapping library available for Flutter!

Check out this independent thesis by Sergey Ushakov, which compares us to `google_maps_flutter` & `mapbox_maps_flutter`. Guess who's the winner ;)

{% embed url="https://archive.org/details/incorporating-maps-into-flutter-a-study-of-mapping-sdks-and-their-integration-in" %}
Original: [https://www.theseus.fi/bitstream/handle/10024/820026/Ushakov\_Sergey.pdf](https://www.theseus.fi/bitstream/handle/10024/820026/Ushakov\_Sergey.pdf)\
Archive: [https://archive.org/details/incorporating-maps-into-flutter-a-study-of-mapping-sdks-and-their-integration-in](https://archive.org/details/incorporating-maps-into-flutter-a-study-of-mapping-sdks-and-their-integration-in)
{% endembed %}
{% endhint %}

## Code Demo

Setting up an interactive and compliant[^1] map is simpler than making your lunch-time coffee! It can be accomplished in just under 30 lines and a minute or two to install.

This code snippet demonstrates **everything** you need for a simple map (in just over 20 lines!), but of course, FM is capable of much more than just this, and you could find yourself lost in the many options available and possibilities opened!

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
      TileLayer( // Display map tiles from any source
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
        userAgentPackageName: 'com.example.app',
        maxNativeZoom: 19, // Scale tiles when the server doesn't support higher zoom levels
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
* Then, for bug reports & feature requests: check for previous issues, then ask in [GitHub Issues](https://github.com/fleaflet/flutter\_map/issues)
* Then, for support & everything else: ask in [flutter\_map Discord server](https://discord.gg/BwpEsjqMAH) or [GitHub Discussions](https://github.com/fleaflet/flutter\_map/discussions)

{% hint style="info" %}
We're a community maintained project and the maintainers would greatly appriciate any help in implementing features and fixing bugs! Feel free to jump in: [https://github.com/fleaflet/flutter\_map/blob/master/CONTRIBUTING.md](https://github.com/fleaflet/flutter\_map/blob/master/CONTRIBUTING.md).

Please remember that we are volunteers and cannot gurantee support. The standard Code of Conduct is here to keep our community a safe and friendly place for everyone: [https://github.com/fleaflet/flutter\_map/blob/master/CODE\_OF\_CONDUCT.md](https://github.com/fleaflet/flutter\_map/blob/master/CODE\_OF\_CONDUCT.md).
{% endhint %}

### FAQs

We get quite a lot of similar questions, so please check if your question is here before you ask!

{% content-ref url="getting-started/explanation/" %}
[explanation](getting-started/explanation/)
{% endcontent-ref %}

<details>

<summary>How can I use a custom map style?<br>How can I prevent POI/labels rotating when the map rotates?<br>How can I remove certain POI/labels from the map?</summary>

Unfortunately, this library cannot provide this functionality. It has no control over the tiles displayed in the `TileLayer`. This is a limitation of the technology, not this library.

This is because raster tiles are just images generated by a 3rd party tile server (dictated by your URL template), and therefore cannot be changed by the library that displays the tiles. Filters can be applied to the entire tile, such as an emulated dark mode, but these effects do not look great.

However, tilesets can be styled. This is the most effective way of using custom styles. These methods may help you with this:&#x20;

* You may wish to use a commercial service like Mapbox Studio, which allows you to style multiple tilesets. See [using-mapbox.md](tile-servers/using-mapbox.md "mention").
* Alternatively, you can experiment with vector tiles. These are not pre-rendered, and so allow any style you desire to be applied on the fly. See [#vector-tiles](getting-started/explanation/raster-vs-vector-tiles.md#vector-tiles "mention").
* Your last option is to serve tiles yourself. See [other-options.md](tile-servers/other-options.md "mention").

</details>

<details>

<summary>How can I route a user between two locations?<br>Why does the <code>Polyline</code> only go in a straight line between two points?</summary>

See [#routing-navigation](layers/polyline-layer.md#routing-navigation "mention").

</details>

<details>

<summary>How can I add a <code>Marker</code> where the user's location is?<br>How can I center the map on the user's location?</summary>

This is beyond the scope of flutter\_map. However, you can use the [community maintained plugin 'flutter\_map\_location\_marker'](https://github.com/tlserver/flutter\_map\_location\_marker) to do this.

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
