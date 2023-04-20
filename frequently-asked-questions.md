---
description: aka. FAQs
---

# Frequently Asked Questions

If you have a question you'd like to add to this page, please let us know over on the Discord server!

You should also read the [explanation](explanation/ "mention") page for a more generalised overview of the most important facts.

<details>

<summary>Custom Tile Styles</summary>

Unfortunately, this library cannot provide this functionality.

Raster tiles are pre-rendered by the tile server, and cannot be changed on the fly. Filters can be applied, such as an emulated dark mode, but these effects do not look great. This is a limitation of the technology, not this library.

However, tilesets can be styled. This is the most effective way of using custom styles. These methods may help you with this:&#x20;

* You may wish to use a commercial service like Mapbox Studio, which allows you to style multiple tilesets. See [using-mapbox.md](tile-servers/using-mapbox.md "mention").
* Alternatively, you can experiment with vector tiles. These are not pre-rendered, and so allow any style you desire to be applied on the fly. See [#vector-tiles](explanation/raster-vs-vector-tiles.md#vector-tiles "mention").
* Your last option is to serve tiles yourself. See [other-options.md](tile-servers/other-options.md "mention").

</details>

<details>

<summary>Prevent 'Labels' Rotation With The Map</summary>

See [#custom-tile-styles](frequently-asked-questions.md#custom-tile-styles "mention"). The reasoning is the same: we don't have control over the stuff inside the `TileLayer`.

</details>

<details>

<summary>Routing/Navigation</summary>

See [#routing-navigation](layers/polyline-layer.md#routing-navigation "mention").

</details>

{% hint style="success" %}
We're adding questions here as we get them!
{% endhint %}
