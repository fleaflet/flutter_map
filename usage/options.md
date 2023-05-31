# Options

To dictate what the map can/should do, regardless of its contents, it needs some guidance!

It provides options that can be categorized into three main parts:

* [Initial positioning](options.md#initial-positioning)\
  Defines the location of the map when it is first loaded
* [Permanent rules](options.md#permanent-rules)\
  Defines restrictions that last throughout the map's lifetime
* [Event handling](event-handling.md)\
  Defines methods that are called on specific map events

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MapOptions-class.html" %}

## Initial Positioning

One part of `MapOptions` responsibilities is to define how the map should be positioned when first loaded. There's two ways to do this (that are incompatible):

* `center` & `zoom`\
  Defines the center coordinates of the map and a zoom level
* `bounds`\
  Defines an area with two/four coordinates that the viewport should fit to

It is possible to also set the map's `rotation` in degrees, if you don't want it North (0°) facing initially.

{% hint style="info" %}
Changing these properties after the map has already been built for the first time will have no effect: they only apply on initialisation.

To control the map programatically, use a `MapController`: [controller.md](controller.md "mention").
{% endhint %}

## Permanent Rules

One part of `MapOptions` responsibilities is to define the restrictions and limitations of the map and what users can/cannot do with it.

You should check [all the available options](https://pub.dev/documentation/flutter\_map/latest/flutter\_map/MapOptions-class.html), but these are recommended for most maps:

* `maxZoom` (and `minZoom`)\
  Limits how far the map can be zoomed by the user, to avoid showing empty tiles
* `maxBounds`\
  Limits how far the map can be moved by the user to a coordinate-based boundary
* `interactiveFlags` - see [`InteractiveFlag`](https://pub.dev/documentation/flutter\_map/latest/flutter\_map.plugin\_api/InteractiveFlag-class.html) for available options\
  Limits what methods the user can interact with the map through (for example, preventing rotation)
* `keepAlive`\
  If `FlutterMap` is located inside a `PageView`, `ListView` or another complex lazy layout, set this `true` to prevent the map from resetting to the [#initial-positioning](options.md#initial-positioning "mention") on rebuild

{% hint style="success" %}
Instead of `maxZoom` (or in addition to), consider setting `maxNativeZoom` per `TileLayer` instead, to allow tiles to scale (and lose quality) on the final zoom level, instead of setting a hard limit.
{% endhint %}

## Event Handling

{% content-ref url="event-handling.md" %}
[event-handling.md](event-handling.md)
{% endcontent-ref %}
