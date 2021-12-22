---
id: how-does-it-work
sidebar_position: 2
---

# How Does It Work?

:::info
This article will take you through the most popular method(s) used by tile server providers, but it can't cover everything. If this doesn't satisfy your curiosity, the OpenStreetMap foundation & Google are your friends.
:::

This library is similar to most other mapping libraries in other languages, so this applies to most other mapping libraries as well.

A mapping library is usually just a wrapper for a particular language that handles requests to servers called 'tile servers'.

## What is a Tile Server?

A tile server is a server accessible on the Internet by everyone, or by only people holding the correct API key.

There are four main types of server configuration, two of which are used together by any server: WMS or WMTS & vector or raster. This wiki will focus on WMTS raster servers, such as the main OpenStreetMaps server, as it is the most commonly used option and is easier to setup and explain for beginners, but you can read about the [options for WMS](/miscellaneous/wms-servers) later on in this wiki. At the moment, [support of vector tiles](/servers/raster-vs-vector-tiles) is limited, but experimental functionality can be added through an existing community maintained plugin.

Simplified, the server holds multiple images in a directory structure that makes it easy to find tiles without searching for references in a database beforehand (see below). These images put together make up the whole world, or area that that tile server supports. One tile is usually really small, under 20KB, but the number of tiles to map the whole world exceeds 60-70GB when compressed.

The main tile server that's free to use and open-source is the Open Street Maps tile server, as mentioned above, a server which provides access to millions of tiles covering the whole Earth. that get updated and maintained by the general public. You can [find other 'semi-endorsed' public servers here](https://wiki.openstreetmap.org/wiki/Tile_servers).

:::danger Terms of Service & Tile Usage Policy
Before using a tile server (especially, but not limited to, free/open-source servers), you must read and agree to the server's Terms of Service or Tile Usage Policy. These are rules defined by the server provider, not by a mapping library (such as `flutter_map`), and define what and what you cannot do using their service/tiles.

You can find the [OSM Tile Server Usage Policy here](https://operations.osmfoundation.org/policies/tiles/), and other servers will likely (but not necessarily) follow similar rules.

It is always recommended to use a private or paid-for server for commercial applications as they usually have a guaranteed up-time and can offer preferable Usage Policies (as they are charging you for it).

`flutter_map` does not accept responsibility for any issues or threats posed by your misuse of external tile servers. Use tile servers at your own risk.
:::

## 'Slippy Map' Convention

_The [slippy map convention is documented extensively here](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames), but this page provides some basics, roughly copied from that page._

The standard Slippy Map path looks like this: '/zoom/x/y.png' or '/x/y/zoom.png'. To note, the image format does not have to be '.png', tile servers also commonly serve as '.jpg' images.

You may also see '/?x={x}&y={y}&zoom={z}', which isn't quite the same as the Slippy Map convention, but it works in essentially the same way, so the below text still applies.

### Zoom

Zoom refers to the zoom level. 1 is the lowest zoom level and contains the whole world in one tile. The higher the number, the more the zoom, and the more the detail, and therefore the less space covered. You can read more about this at [wiki.openstreetmap.org/wiki/Zoom_levels](https://wiki.openstreetmap.org/wiki/Zoom_levels). Most servers go up to 18, some up to 19, but no servers (as of writing) have a maximum limit above 22.

### X & Y

X and Y are values corresponding to the longitude and latitude of a location, however they are not actual longitude and latitude. See [wiki.openstreetmap.org/wiki/Slippy_map_tilenames](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Implementations).

![Lat/Lng to x/y/z](https://wiki.openstreetmap.org/w/images/thumb/a/a5/Latlon_to_tile.png/450px-Latlon_to_tile.png)

![x/y/z to Lat/Lng](https://wiki.openstreetmap.org/w/images/thumb/1/1f/Tile_to_latlon.png/450px-Tile_to_latlon.png)

These images show the mathematics required to convert between Latitude and Longitude & the x/y/z format and vice-versa respectively. All credit for the above images goes to the Open Street Maps foundation.

## Tile Providers

In this `flutter_map` package, the classes that conduct this maths to get these tiles are called 'tile providers'.

However, these do a lot more than just the maths. They do the maths, format the appropriate URL, potentially stagger the URL (not to get rate limited by the browser or engine), make the request, get the image, process (and potentially store) the image and finally give it back to the main process to paint onto the map for the user to see.

Unless you choose to make your own custom tile provider ([the guide for which can be found here](http://localhost:3000/plugins/how-to-make-a-plugin#where-a-new-layer-is-not-created)), you should never need to handle this yourself.

## Map Layers

Once the tile provider has dealt with the tile, it sends it to a map layer to get painted onto the map. This can be done using canvases (such as in HTML5 for the web), or, in the case of `flutter_map`, Flutter widgets.

The map layers also handle user interaction, such as panning, zooming, rotating and tapping.
