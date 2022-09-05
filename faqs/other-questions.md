# Other Questions

If you have a question you'd like to add to this page, please let us know over on the Discord server!

You should also read the [explanation](../getting-started/explanation/ "mention") page for a more generalised overview of the most important facts.

<details>

<summary>Routing</summary>

Routing is currently out-of-scope for 'flutter\_map'. However, if you can get a list of coordinates from a 3rd party, then you can use the [polyline-layer.md](../usage/layers/polyline-layer.md "mention") to show it!

A good open source option is [OSRM](http://project-osrm.org/), but if you want higher reliability and more functionality such as real-time based routing, you may want to try a commercial solution such as Mapbox or Google Maps.

</details>

<details>

<summary>Offline Mapping</summary>

See [#offline-mapping](../usage/layers/tile-layer/tile-providers.md#offline-mapping "mention").

</details>

<details>

<summary>Custom Tile Styles</summary>

Unfortunately, this library cannot provide this functionality.

Raster tiles are pre-rendered by the tile server, and cannot be changed on the fly. Filters can be applied, such as an emulated dark mode, but these effects do not look great. This is a limitation of the technology, not this library.

However, tilesets can be styled. This is the most effective way of using custom styles. These methods may help you with this:&#x20;

* You may wish to use a commercial service like Mapbox Studio, which allows you to style multiple tilesets. See [using-mapbox.md](../tile-servers/using-mapbox.md "mention").
* Alternatively, you can experiment with vector tiles. These are not pre-rendered, and so allow any style you desire to be applied on the fly. See [#vector-tiles](../getting-started/explanation/raster-vs-vector-tiles.md#vector-tiles "mention").
* Your last option is to serve tiles yourself. See [other-options.md](../tile-servers/other-options.md "mention").

</details>

<details>

<summary>Animate <code>MapController</code></summary>

It's possible to animate the movements made by a `MapController`, although this isn't implemented in this library.

For an example of how to do this, please see the [example app's Animated Map Controller page](https://github.com/fleaflet/flutter\_map/blob/master/example/lib/pages/animated\_map\_controller.dart).

</details>

<details>

<summary>Map Resetting in Complex Layouts</summary>

See [#keep-alive-keepalive](../usage/options/recommended-options.md#keep-alive-keepalive "mention").

</details>

<details>

<summary><code>LateInitializationError</code>s &#x26; <code>BadState</code> Errors</summary>

See [map-controller-issues.md](map-controller-issues.md "mention").

</details>

{% hint style="success" %}
We're adding questions here as we get them!
{% endhint %}
