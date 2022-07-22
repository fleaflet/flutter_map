# Other Questions

{% hint style="info" %}
We're writing this documentation page now! Please hold tight for now, and refer to the GitHub issue tracker, or ask for help on the Discord server.
{% endhint %}

If you have a question you'd like to add to this page, please let us know over on the Discord server!

<details>

<summary>How Does All Of This Work?</summary>

Luckily, we have a documentation page for that! See [explanation](../getting-started/explanation/ "mention").

</details>

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
