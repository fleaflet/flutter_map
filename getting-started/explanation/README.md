# How Does It Work?

{% hint style="info" %}
If you don't know about standard map things, such as the latitude/longitude system and projections, you should probably read about these first!

If you want a truly British insight into this, look no further than: [https://youtu.be/3mHC-Pf8-dU](https://youtu.be/3mHC-Pf8-dU) & [https://youtu.be/jtBV3GgQLg8](https://youtu.be/jtBV3GgQLg8). Otherwise I'd recommend something else.
{% endhint %}

This library is similar to most other mapping libraries in other languages, so this applies to most other mapping libraries as well.

A mapping library is usually just a wrapper for a particular language that handles requests to servers called 'tile servers', and displays it in an interactive view for the user.

## What is a Tile Server?

A tile server is a server accessible on the Internet by everyone, or by only people holding the correct API key.

There are four main types of server configuration, two of which are used together by any server: WMS or WMTS (aka. CARTO) & vector or raster. This wiki will focus on WMTS raster servers, such as the main OpenStreetMaps server, as it is the most commonly used option and is easier to setup and explain for beginners, but you can read about the options for WMS later on in this wiki. At the moment, support of vector tiles is limited, but experimental functionality can be added through an existing community maintained plugin.

Simplified, the server holds multiple images in a directory structure that makes it easy to find tiles without searching for references in a database beforehand (see below). These images put together make up the whole world, or area that that tile server supports.\
One tile is usually really small when rendered, under 20KB for most tiles. However, the entire planet data consumes 1.5TB when un-rendered and uncompressed from the 110GB download archive. When all tiles are rendered, they add up to over 54TB! Most servers render tiles on-the-fly to get around this.

The main tile server that's free to use and open-source is the Open Street Maps tile server, as mentioned above, a server which provides access to millions of tiles covering the whole Earth. that get updated and maintained by the general public. You can [find other 'semi-endorsed' public servers here](https://wiki.openstreetmap.org/wiki/Tile\_servers).

## 'Slippy Map' Convention

_The_ [_slippy map convention is documented extensively here_](https://wiki.openstreetmap.org/wiki/Slippy\_map\_tilenames)_, but this page provides some basics, roughly copied from that page._

The standard Slippy Map path looks like this: '/zoom/x/y.png' or '/x/y/zoom.png'. To note, the image format does not have to be '.png', tile servers also commonly serve as '.jpg' images.

You may also see '/?x={x}\&y={y}\&zoom={z}', which isn't quite the same as the Slippy Map convention, but it works in essentially the same way, so the below text still applies.

### Zoom

Zoom refers to the zoom level. 1 is the lowest zoom level and contains the whole world in one tile. The higher the number, the more the zoom, and the more the detail, and therefore the less space covered. You can read more about this at [wiki.openstreetmap.org/wiki/Zoom\_levels](https://wiki.openstreetmap.org/wiki/Zoom\_levels). Most servers go up to 18, some up to 19, but no servers (as of writing) have a maximum limit above 22.

### X & Y

X and Y are values corresponding to the longitude and latitude of a location, however they are not actual longitude and latitude. See [wiki.openstreetmap.org/wiki/Slippy\_map\_tilenames](https://wiki.openstreetmap.org/wiki/Slippy\_map\_tilenames#Implementations).

![Lat/Lng to x/y/z](https://wiki.openstreetmap.org/w/images/thumb/a/a5/Latlon\_to\_tile.png/450px-Latlon\_to\_tile.png)

![x/y/z to Lat/Lng](https://wiki.openstreetmap.org/w/images/thumb/1/1f/Tile\_to\_latlon.png/450px-Tile\_to\_latlon.png)

These images show the mathematics required to convert between Latitude and Longitude & the x/y/z format and vice-versa respectively. All credit for the above images goes to the Open Street Maps foundation.

## Tile Providers

In this 'flutter\_map' package, the classes that conduct this maths to get these tiles are called 'tile providers'.

However, these do a lot more than just the maths. They do the maths, format the appropriate URL, potentially stagger the URL (not to get rate limited by the browser or engine), make the request, get the image, process (and potentially store) the image and finally give it back to the main process to paint onto the map for the user to see.

Unless you choose to implement your own custom tile provider, you should never need to handle this yourself.

For more information about setting up a tile provider within the API, see [tile-providers.md](../../usage/layers/tile-layer/tile-providers.md "mention").

## Map Layers

Once the tile provider has dealt with the tile, it sends it to a map layer to get painted onto the map. This can be done using canvases (such as in HTML5 for the web), or, in the case of 'flutter\_map', Flutter widgets.

The map layers also handle user interaction, such as panning, zooming, rotating and tapping.
