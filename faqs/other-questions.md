# Other Questions

If you have a question you'd like to add to this page, please let us know over on the Discord server!

You should also read the [explanation](../getting-started/explanation/ "mention") page for a more generalised overview of the most important facts.

<details>

<summary>Map Keeps Resetting In Complex Layouts</summary>

If you are using a more complex layout in your application - such as using the map inside a `ListView`, a `PageView`, or a tabbed layout - you may find that the map resets when it appears/scrolls back into view.

To prevent this, you may need to use the [#keep-alive-keepalive](../usage/options/recommended-options.md#keep-alive-keepalive "mention") option.

</details>

<details>

<summary>Updating The <code>templateUrl</code> Doesn't Update The Tiles</summary>

If you're updating the template URL dynamically, you'll need to reset the `TileLayerOptions` by causing it to rebuild, or using the `reset` functionality.

See [#reset-stream-reset](../usage/layers/tile-layer/other-options.md#reset-stream-reset "mention").

</details>

<details>

<summary>How Can I Implement Routing?</summary>

Routing is currently out-of-scope for 'flutter\_map'. However, if you can get a list of coordinates from a 3rd party, then you can use the [polyline-layer.md](../usage/layers/polyline-layer.md "mention") to show it!

A good open source option is [OSRM](http://project-osrm.org/), but if you want higher reliability and more functionality such as real-time based routing, you may want to try a commercial solution such as Mapbox or Google Maps.

</details>

<details>

<summary>Is It Possible To Change The Style Of Tiles?</summary>

In a word, no.

Raster tiles are pre-rendered by the tile server, and cannot be changed on the fly. Filters can be applied, such as an emulated dark mode, but these effects do not look great. This is a limitation of the technology, not this library.

However, tilesets can be styled. This is the most effective way of using custom styles. These methods may help you with this:&#x20;

* You may wish to use a commercial service like Mapbox Studio, which allows you to style multiple tilesets. See [using-mapbox.md](../tile-servers/using-mapbox.md "mention").
* Alternatively, you can experiment with vector tiles. These are not pre-rendered, and so allow any style you desire to be applied on the fly. See [#vector-tiles](../getting-started/explanation/raster-vs-vector-tiles.md#vector-tiles "mention").
* If you want to stick with vanilla 'flutter\_map', your last option is to serve tiles yourself. See [other-options.md](../tile-servers/other-options.md "mention").

</details>

{% hint style="info" %}
We're adding questions here as we get them!
{% endhint %}
