---
description: >-
  A versatile mapping package for Flutter. Simple and easy to learn, yet
  completely customizable and configurable, it's the best choice for mapping in
  your Flutter app.
cover: .gitbook/assets/Cover.jpg
coverY: -35
---

# flutter\_map

[![pub.dev](https://camo.githubusercontent.com/a796d19cced2795c62dee9f3b165665449dbfd0bd46bf39beceef3371f14ebee/68747470733a2f2f696d672e736869656c64732e696f2f7075622f762f666c75747465725f6d61702e7376673f6c6162656c3d4c61746573742b56657273696f6e)](https://pub.dev/packages/flutter\_map) [![stars](https://camo.githubusercontent.com/7e6d80df311cbd5e68edf6994e404a97af85c84f7ec66614875dba12f055c246/68747470733a2f2f62616467656e2e6e65742f6769746875622f73746172732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d737461727326636f6c6f723d677265656e2669636f6e3d676974687562)](https://github.com/fleaflet/flutter\_map/stargazers) [![likes](https://camo.githubusercontent.com/450afb6eb57ffb0e3cdae61f8a90d51541dbe09eaddcc69900cb09a91762363a/68747470733a2f2f696d672e736869656c64732e696f2f7075622f6c696b65732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score)      [![Open Issues](https://camo.githubusercontent.com/3f89334e961516c8b3eef4879a287818a2b8e6523e5f9f8d3767e1d98c8a4f44/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d6973737565732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b49737375657326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc) [![Open PRs](https://camo.githubusercontent.com/2d48f34537361cf13f775e8c88c5884a7a7b280469b319453b2ccdabdee1f2db/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d7072732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b50527326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc)

{% hint style="danger" %}
**Known Issues (v7.0.x: `PolygonLayer` & `PolylineLayer`)**

v7.0.1 currently contains a potentially serious performance bug in the `PolygonLayer` and `PolylineLayer`, inadvertently introduced attempting to fix a bug in v7.0.0. If you experience issues with slow updates when elements are modified, or if elements appear to disappear and reappear when zooming or modifying them, please downgrade to v7.0.0.

v7.0.0 contains an issue where modifying elements within a `PolygonLayer` and `PolylineLayer` does not cause the element to update. To resolve this issue, create a copy of the `points` list when updating it - for example, use `List.from` in the element's constructor.&#x20;

We are working to fix the issue.
{% endhint %}

## Feature Highlights

<table data-card-size="large" data-view="cards" data-full-width="false"><thead><tr><th align="center"></th><th align="center"></th><th data-hidden data-card-cover data-type="files"></th></tr></thead><tbody><tr><td align="center">🗺️ <strong>Supports any* map style</strong></td><td align="center">We natively support any static raster tile server, including from a web server or even from the local file system or app asset store.<br>No more vendor lock-in!</td><td></td></tr><tr><td align="center">💪 <strong>Stress-free setup and use</strong></td><td align="center">Migrating from a commercial library such as Google Maps has never been easier! No more complex platform-specific setup, no more API keys: just add a widget and you're done.</td><td></td></tr><tr><td align="center">🧩 <strong>Wide ecosystem of plugins</strong></td><td align="center">In the unlikely event that flutter_map doesn't natively contain something you need, just check to see if there's a community maintained plugin that does what you need!</td><td></td></tr><tr><td align="center">➕ <strong>Add other map features easily</strong></td><td align="center">Add polygons, polylines, and markers/pins to your map easily and quickly. Markers support displaying any widget you might want.</td><td></td></tr></tbody></table>



<details>

<summary>How does flutter_map compare to other mapping libraries?</summary>

This usually refers to libraries such as 'mapbox\_gl' and 'google\_maps\_flutter'. In most ways, it is better, in some it is worse.

flutter\_map wins on:

* Less vendor lock-in (and potentially reduced costs)\
  You're not locked into a particular tile server with us - choose from hundreds of options, or build your own!
* Customizability & extensibility\
  Add all sorts of layers to display custom widgets and data on top of your map, and choose from flutter\_map's many community maintained plugins to add even more functionality!
* Ease of use/setup\
  We don't require any API keys or platform specific setup (other than enabling the Internet permission!), so you can get started quicker, and make changes without fear of breaking your release application.
* Support quality and frequency\
  Most questions are answered and resolved within 12-24 hours, thanks to our dedicated maintainers and community.&#x20;

However, alternatives may win on:

* Performance\*\
  flutter\_map's performance is very adequate for the vast majority of applications, and many big businesses use FM to provide maps in their Flutter app.\
  However, if you're using high-thousands of `Markers` or `Polygons` and such like, alternatives may win, purely because they use platform views and GL, and so can do calculations outside of Dart.
* ... and that's pretty much it 😉

</details>

## Code Demo

Setting up an interactive and compliant[^1] map is simpler than making your lunch-time coffee! It can be accomplished in just under 30 lines and a minute or two to install.

This code snippet demonstrates **everything** you need for a simple map (in just over 20 lines!), but of course, FM is capable of much more than just this, and you could find yourself lost in the many options available and possibilities opened!

<pre class="language-dart" data-line-numbers><code class="lang-dart">import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

@override
Widget build(BuildContext context) {
  return <a data-footnote-ref href="#user-content-fn-2">FlutterMap</a>(
    <a data-footnote-ref href="#user-content-fn-3">options</a>: MapOptions(
      initialCenter: LatLng(51.509364, -0.128928),
      initialZoom: 9.2,
    ),
    <a data-footnote-ref href="#user-content-fn-4">children</a>: [
      TileLayer(
        <a data-footnote-ref href="#user-content-fn-5">urlTemplate</a>: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),
      <a data-footnote-ref href="#user-content-fn-6">RichAttributionWidget</a>(
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => <a data-footnote-ref href="#user-content-fn-7">launchUrl</a>(Uri.parse('https://openstreetmap.org/copyright')),
          ),
        ],
      ),
    ],
  );
}
</code></pre>

## Get Help

Not quite sure about something? No problem. Please get in touch via any of these methods, and we'll be with you as soon as possible. Please remember that we are volunteers, so we cannot guarantee (fast) support.

* For bug reports & feature requests: check the [#faqs](./#faqs "mention") then [GitHub Issues](https://github.com/fleaflet/flutter\_map/issues)
* For support & everything else: check the [#faqs](./#faqs "mention") then [flutter\_map Discord server](https://discord.gg/BwpEsjqMAH)

{% hint style="info" %}
Due to time shortages, wait times for feature request implementations are currently extremely long and may not happen at all.

We'd love to have your contributions to add your own or others' pull requests!
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

[^2]: As simple as just another widget...

[^3]: Plenty of customisable options available

[^4]: Choose from a variety of features to display on your map

[^5]: Connect to any\* map server/provider

[^6]: Stylish attribution required? No problem!

[^7]: _Requires url\_launcher to be installed separately_
