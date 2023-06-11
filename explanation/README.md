# How Does It Work?

{% hint style="info" %}
If you don't know about standard map things, such as the latitude/longitude system and projections, you should probably read about these first!

_If you want a truly British insight into this, look no further than:_ [_https://youtu.be/3mHC-Pf8-dU_](https://youtu.be/3mHC-Pf8-dU) _&_ [_https://youtu.be/jtBV3GgQLg8_](https://youtu.be/jtBV3GgQLg8)_._
{% endhint %}

## Layers

Interactive maps are often[^1] formed from multiple layers of data, which can be panned (moved), rotated, ~~and sometimes tilted/pitched~~, based on the user's gesture input, or another programmatic control.

## Tile Basics

One type of layer included on every map is known as a tile layer, which displays tiles, square segments of a map.

When multiple tiles, which are each the same dimensions, are laid out around each other, they give the illusion of one continuous map.

Tiles can be referenced/identified in a few different ways, such as:

* Slippy Map Convention (the most popular/common)
* [TMS](https://wiki.openstreetmap.org/wiki/TMS) (very similar to the Slippy Map Convention)
* [WMS](https://wiki.openstreetmap.org/wiki/WMS)&#x20;
* [WMTS](https://en.wikipedia.org/wiki/Web\_Map\_Tile\_Service)

Tiles themselves can be of two types:

* Raster\
  Each tile is a normal pre-rendered standard image, such as JPG or PNG
* Vector\
  Each tile is a special format containing the data for the tile, and is then rendered by the end library

This library/documentation focuses on maps accessible via the Slippy Map Convention, although all are supported.

This library only supports raster tiles. See [raster-vs-vector-tiles.md](raster-vs-vector-tiles.md "mention") for more information.

### Slippy Map Convention

{% hint style="info" %}
For more information about the Slippy Map Convention, visit [the OpenStreetMap Wiki](https://wiki.openstreetmap.org/wiki/Slippy\_map\_tilenames).
{% endhint %}

Slippy map tiles are accessed by 3 coordinates, x/y/z.

X & Y coordinates correspond to all the latitudes and longitudes contained within that tile, however they are not actual longitude and latitude. For example, geographic coordinate (61.127, -0.123) [might be](#user-content-fn-2)[^2] in the tile (128983, 430239).

The Z value represents the current zoom level, where one tile ([0/0/0](https://tile.openstreetmap.org/0/0/0.png)) covers the entire planet with extremely low detail at level 0, to level 20 (although some tile servers will support even higher zoom levels) where over 1 trillion tiles are required to cover the entire surface of the Earth.

## Sourcing Tiles

Tiles, especially raster tiles, take a lot of computing power and time to generate, because of the massive scale of all the input and output data. Therefore, most tiles are sourced externally, from an online tile server (either publicly or by users holding an API key), or sometimes from the local filesystem or asset store of the app.

{% content-ref url="../tile-servers/other-options.md" %}
[other-options.md](../tile-servers/other-options.md)
{% endcontent-ref %}

## Tile Providers

A tile provider (within flutter\_map) is responsible for:

* Constructing the path/URL to a tile, when given its coordinates (x/y/z): [#slippy-map-convention](./#slippy-map-convention "mention")
* Using an `ImageProvider` or other mechanism to fetch that tile: [#sourcing-tiles](./#sourcing-tiles "mention")
* Performing any other processing steps, such as caching

But don't worry! flutter\_map (or a plugin) creates a provider for you, so for most use cases and tile sources, you shouldn't need to handle this yourself!

{% content-ref url="../layers/tile-layer/tile-providers.md" %}
[tile-providers.md](../layers/tile-layer/tile-providers.md)
{% endcontent-ref %}

{% hint style="info" %}
This can be quite confusing for newcomers!

Within this library, 'tile providers' use 'tile servers' to retrieve tiles from the Internet. On the other hand, 'tile servers' and external sites usually use 'tile providers' to mean 'tile servers'!
{% endhint %}

[^1]: Most mapping libraries operate in this way

[^2]: This is not a real example of this relationship.
