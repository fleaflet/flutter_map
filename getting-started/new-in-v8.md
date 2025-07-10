# 🚀 What's New In v8.2?

## Overview

Here's some highlights since v8.0:

{% hint style="success" %}
## **Automatically enabled lightweight built-in caching & aborting of in-flight HTTP requests for obsolete tiles**

The `NetworkTileProvider` has had a massive functionality boost!

Built-in caching helps you, your users, and the tile server, and is enabled by default for maximum ease. You could also switch it out with a custom implementation, or disable it altogether if you prefer. Find out more in [caching.md](../layers/tile-layer/caching.md "mention").

You may be using the `CancellableNetworkTileProvider`, which allowed in-flight HTTP requests to be aborted when the tiles would no longer be displayed, helping to improve performance and usability. Unfortunately, it isn't compatible with built-in caching. Fortunately, it's also been deprecated - its functionality is now available in the core! 'package:http' v1.5.0-beta ([#1773](https://github.com/dart-lang/http/pull/1773)) supports aborting requests with the 3 default clients natively, so Dio is no longer required. This makes it easier for you and for us!
{% endhint %}

{% hint style="success" %}
## &#x20;**Inverted filling for `PolygonLayer` & multi-yet-single world support for `Poly*Layer`**

This continues the work on multi-world support (thanks monsieurtanuki), and fixes an issue that occured where users used a `Polygon` covering the entire world, with holes as cut outs.

_This feature was bounty-funded, thanks to our generous_ [supporters.md](../thanks/supporters.md "mention")_, and the community! We hope to open more bounties in future._
{% endhint %}

{% hint style="success" %}
## No more grey background at the North and South edges of your map (optionally)

Thanks to the community, a new `ContainCameraLatitude` `CameraConstraint` is available, which keeps just the world in view at all times. At the moment, it still needs enabling manually.

Check out the effect in our demo for [multi-world functionality](https://demo.fleaflet.dev/repeated_worlds). You can enable it in your project just by passing the object to the `MapOptions.cameraConstraint` option.
{% endhint %}

{% hint style="success" %}
## Polygon label placement improvements

This is split into 3 parts:

* The old method of picking a placement algorithm has been deprecated and been replaced with a new, extensible system - it's still just as easy to use as the old one
* Thanks to the community, a new placement algorithm has been added: an improved centroid algorithm using the 'signed area centroid' algorithm - this is the new default, but the old algorithm is still available
* The polylabel placement algorithm has been given a fresh lick of paint and uses a more modern Dart implementation to improve performance and customizability

See how to migrate to the new system below.
{% endhint %}

{% hint style="success" %}
## Documentation improvements

This documentation has also had a bit of a renewal!

* Follow the new guide to setup a `TileLayer` as we recommend: [#recommended-setup](../layers/tile-layer/#recommended-setup "mention"). More to come soon!
* The guide for interactive layers has been simplified, reworked, and example added. Check it out: [layer-interactivity](../layers/layer-interactivity/ "mention").
* We've added some information about using flutter\_map with the OpenStreetMap public tile servers: [using-openstreetmap-direct.md](../tile-servers/using-openstreetmap-direct.md "mention").
{% endhint %}

{% hint style="warning" %}
## Information will appear in console when a `TileLayer` is loaded using one of the OpenStreetMap tile servers (in debug mode)

Additionally, where an appropriate User-Agent header (which identifies your app to the server) is not set - for example, through `TileLayer.userAgentPackageName`, or directly through the tile provider's HTTP headers configuration - a warning will appear in console (in debug mode), advising you to set a UA.

In future, we may block users which do not set a valid UA identifier for this server.

For more information, see [using-openstreetmap-direct.md](../tile-servers/using-openstreetmap-direct.md "mention").
{% endhint %}

That's already a lot, but it's only scratching the surface. Alongside the community, we've improved our example app, [reduced the size of our demo & package](https://github.com/fleaflet/flutter_map/pull/2056), [added even more customizability and fine-grained control](#user-content-fn-1)[^1] - not even to mention the multiple bug fixes and other performance improvements.

Why not check out the CHANGELOG for the full list of curated changes, and the full commit and contributor listing if you like all the details:

{% embed url="https://pub.dev/packages/flutter_map/changelog" %}
CHANGELOG
{% endembed %}

{% embed url="https://github.com/fleaflet/flutter_map/compare/v8.1.1...v8.2.0" %}

{% hint style="info" %}
For completeness, here were the highlights from v8.0:

* Unbounded horizontal scrolling
* Keyboard controls for map gestures
* Performance improvements (particularly with `Polygon/lineLayer`)
{% endhint %}

## Migration

### To v8.2

{% hint style="success" %}
v8.2 doesn't contain any API breaking changes, but it does contain deprecations and a small change in potential display output - we suggest preparing for the next breaking release whenever you can
{% endhint %}

<details>

<summary>Changes to <code>Polygon</code> label placement</summary>

It's usually simple to follow the deprecation messages/warnings in your IDE. The changes are described here for completeness.

There's two main changes:

* The default placement algorithm has been changed\
  The new default algorithm adopts the old name (`centroid`), with the old name becoming `simpleCentroid` - it's an improvement over the old algorithm
* The `Polygon.labelPlacement` property & `PolygonLabelPlacement` enum have been deprecated, replaced with `Polygon.labelPlacementCalculator` and `PolygonLabelPlacementCalculator`  respectively

Here's the mapping of old enum values to new objects:

* old default / `.centroid` -> `.centroid()` (new algorithm)
* `.centroidWithMultiWorld` -> `.simpleMultiWorldCentroid()`
* `.polylabel` -> `.polylabel()`
* (new) `.simpleCentroid()`

{% hint style="warning" %}
Note that only the `simpleMultiWorldCentroid` calculator supports polygons which may lie across the anti-meridian.
{% endhint %}

</details>

<details>

<summary>Deprecation of official <code>CancellableNetworkTileProvider</code> plugin</summary>

As described above, its primary purpose is now fulfilled by default in the `NetworkTileProvider`. You can switch back to that and remove the dependency from your project.

</details>

### To v8.0

{% hint style="success" %}
**Migrating to v8 should be pain-free for most apps, but some major changes are likely for plugins.**

Some breaking changes have been made. The amount of migration required will depend on how much your project uses more advanced functionality. Basic apps are unlikely to require migration.
{% endhint %}

<details>

<summary>Most uses of <a href="https://api.flutter.dev/flutter/dart-math/Point-class.html"><code>Point&#x3C;double></code></a> replaced by <a href="https://api.flutter.dev/flutter/dart-ui/Offset-class.html"><code>Offset</code></a> &#x26; <a href="https://api.flutter.dev/flutter/dart-ui/Size-class.html"><code>Size</code></a>, <a href="https://pub.dev/documentation/flutter_map/7.0.1/flutter_map/Bounds-class.html"><code>Bounds&#x3C;double></code></a> by <a href="https://api.flutter.dev/flutter/dart-ui/Rect-class.html"><code>Rect</code></a>, and <a href="https://pub.dev/documentation/flutter_map/7.0.1/flutter_map/Bounds-class.html"><code>Bounds&#x3C;int></code></a> by <code>(IntegerBounds)</code></summary>

With the exception of some areas, uses of 'dart:math' objects, such as `Point`, have been replaced by equivalents from 'dart:ui' and Flutter libraries. There's multiple reasons for this:

* These classes have been described as [legacy since Feb 2024](https://github.com/dart-lang/sdk/commit/885126e51bf2d0c612a42ba55395ac4f4d9f7b42) in Dart/Flutter, and will be [deprecated in future](https://github.com/dart-lang/sdk/issues/54852)
* This reduces internal casting (which we did a whole lot) and usage of generic types ([which are inefficient](https://github.com/dart-lang/sdk/issues/53912)), which has increased performance by around a millisecond or three (in a simple example)
* The tooling and functionality provided by Dart/Flutter reduce the amount we need to maintain internally (reducing duplication), and work better together (such as easily building `Rect`s from `Offset`s and `Size`s

This breaks a large number of coordinate handling functions, such as those converting between geographic coordinates and screen space coordinates (the changed ones) in the `MapCamera`. We've also renamed some of these functions to remove references to 'point' and replace them with 'offset'.

Most migrations should be self explanatory. If necessary, you can [view the PR](https://github.com/fleaflet/flutter_map/pull/1996) to see what happened to a method you were using - there's very likely a close replacement! Some methods have been moved to internal usage only, but there's always easy alternatives.

Some external libraries still use the previous objects, and some of our use-cases are just not yet ready to be replaced by these options yet, so you may still find some of the old objects hiding around the codebase. `IntegerBounds` is internal only.

</details>

<details>

<summary><code>TileLayer.tileSize</code> replaced by <code>tileDimension</code></summary>

Just changing the argument identifier should be enough - we've just restricted the type to be an integer. You can't get tiles in fractional pixels anyway!

This renaming is also persisted throughout the internals.

</details>

[^1]: such as [#2070](https://github.com/fleaflet/flutter_map/pull/2070) & [#2101](https://github.com/fleaflet/flutter_map/pull/2101)
