# Other Options

## Other Servers

There are plenty of other tile servers you can choose from, free or paid. Most provide a static tile service/API, usually called Static Tiles or just Tile Requests (if no vector tiles are supported).

A good catalogue of servers (usually called Providers elsewhere) can be found at the websites below:

{% embed url="https://wiki.openstreetmap.org/wiki/Raster_tile_providers" %}

{% embed url="https://switch2osm.org/providers/" %}

{% hint style="info" %}
Google Maps does not document a static raster tile server. Therefore, flutter\_map is unable to show Google Maps.

_There is an undocumented endpoint available, however it violates the Google Maps Platform ToS._
{% endhint %}

> If you're responsible for a tile server, and want to have your tile server and setup instructions listed in this documentation, please get in touch!

## Serving Your Own Tiles

Switch2OSM also provides detailed instructions on how to serve your own tiles: this can be surprisingly economical and enjoyable if you don't mind a few hours in a Linux console.

However, this will require a very high-spec computer, especially for larger areas, and hosting this might be more complicated than it's worth. It's very difficult to fully understand the technologies involved.

{% embed url="https://switch2osm.org/serving-tiles/" %}
