---
description: A high level overview for those new to 'web' maps
---

# ❔ How Does It Work?

{% hint style="success" %}
Unlike other popular mapping solutions, flutter\_map doesn't come with an opinion on the best map style/tiles to use, so you'll need to **bring your own tiles** - either using a service, such as those listed in Tile Servers, or by creating and using your own custom ones!

We then allow you to add more on top of these tiles, and control and customize as far as you need.

**It's a client to display** [**'tiled & WMS web' maps**](https://en.wikipedia.org/wiki/Tiled_web_map) **and other map features - not a map itself.**
{% endhint %}

{% stepper %}
{% step %}
### 👀 Tile Layer

The basis of a map is the layer which shows square images, known as 'tiles'. When placed adjacent, this creates a single map! This can be panned (moved), rotated, and zoomed, to load new tiles dynamically. To show more detail, more images of the same dimensions are loaded in place.

<figure><img src="../../.gitbook/assets/image (1).png" alt=""><figcaption><p><a href="https://commons.wikimedia.org/wiki/File:XYZ_Tiles.png">https://commons.wikimedia.org/wiki/File:XYZ_Tiles.png</a></p></figcaption></figure>

There's loads of ways to source (see Tile Servers), store ([raster-vs-vector-tiles.md](raster-vs-vector-tiles.md "mention")), and reference (eg. XYZ vs WMS) tiles! We support most of them, _except vector tiles_. This documentation primarily uses examples referring to [Slippy Maps](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames) implemented with XYZ referencing, but we also support many other kinds of maps.

However, you don't need to worry about most of this! Just follow the instructions from your source and it's easy to figure out how to use them in flutter\_map.

See [tile-layer](../../layers/tile-layer/ "mention")for more information.
{% endstep %}

{% step %}
### 🤩 More Layers... More... More...

You can put any other kind of layer (or `Widget`) on top of your `TileLayer`. You can even put another `TileLayer` in! See our [Layers](./#layers) catalogue, [make your own layers](../../plugins/create/layers.md) directly in Flutter, or use one of the excellent [community-maintained plugins](../../plugins/list.md)!
{% endstep %}

{% step %}
### 🛠️ Configure The Map

Once it looks how you imagined, you need it to act like you imagined. flutter\_map provides comprehensive customizability for gesture/interactivity control & initial positioning. See [options](../../usage/options/ "mention") for more info.
{% endstep %}

{% step %}
### 🎮 Control The Map

You can also control the map programmatically using a simple controller pattern. See [programmatic-interaction.md](../../usage/programmatic-interaction.md "mention") for more info.
{% endstep %}
{% endstepper %}

{% hint style="info" %}
Most map client libraries will work in a similar way, so if you've used [leaflet.js](https://leafletjs.com/) or [OpenLayers](https://openlayers.org/) before, you'll be right at home :smile:.
{% endhint %}

See the code demo on the landing page to see how easy it is and how it all fits together in code, and see what's possible in our example app.

{% content-ref url="../../" %}
[..](../../)
{% endcontent-ref %}

{% content-ref url="../demo-and-examples.md" %}
[demo-and-examples.md](../demo-and-examples.md)
{% endcontent-ref %}
