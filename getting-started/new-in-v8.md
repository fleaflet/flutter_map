# 🚀 What's New In v8?

## Overview

Here's some highlights:

{% hint style="success" %}
**🎉 Unbounded horizontal scrolling -** [**#1948**](https://github.com/fleaflet/flutter_map/pull/1948) **&** [**#1969**](https://github.com/fleaflet/flutter_map/pull/1969) **by monsieurtanuki**

We're repeating the trend from v7, and introducing yet another feature that's been continuously requested for longer than we can remember 😂.

Thanks to the hard work of external contributors, you can now pan and fling across the anti-meridian as much as you want (when using the default map projection only). Polygons and polylines also cross the boundary without issues as well, and, alongside markers, will appear on all 'worlds'.

This is the first bounty-funded pull request to flutter\_map, thanks to our generous [supporters.md](../thanks/supporters.md "mention")! We hope to open more bounties in future, but you can also add a bounty on a PR as well (just contact us).
{% endhint %}

{% hint style="success" %}
**Keyboard controls for map gestures -** [**#1987**](https://github.com/fleaflet/flutter_map/pull/1987)

Maybe not quite as highly requested as horizontal scrolling, but we think keyboard controls were missing, a fairly obvious hole on desktop and web platforms. So we've added them!

Supports arrow & `WASD` keys for panning, `QE` keys for rotation, and `RF` keys for zoom. All key handlers are based on the physical layout of the QWERTY keyboard, so users using other keyboards will be able to use whichever keys are physically located in the same position. These are all optionally controllable via `KeyboardOptions` for `MapOptions` - only arrow keys are enabled by default.

(If you were using flutter\_map for developing a game for some reason, this might also be useful 😂)
{% endhint %}

{% hint style="info" %}
We've also fixed a major performance bug with simplification on `Polygon/lineLayer`s. If you previously disabled simplification to workaround the bug and improve performance, we recommend considering re-enabling it.
{% endhint %}

We've also made other changes to improve the experience for your users. Checkout the CHANGELOG for the curated changes, and the full commit listing for all the small details.&#x20;

{% embed url="https://github.com/fleaflet/flutter_map/blob/master/CHANGELOG.md" %}
Curated CHANGELOG
{% endembed %}

{% embed url="https://github.com/fleaflet/flutter_map/compare/v7.0.2...master" %}
Full Commit Listing
{% endembed %}

## Migration

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
