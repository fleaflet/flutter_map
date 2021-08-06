---
id: how-does-it-work
sidebar_position: 2
---

# How Does It Work?

This library is similar to most other mapping libraries in other languages, so this applies to most other mapping libraries as well.

A mapping library is usually just a wrapper for a particular language that handles requests to servers called 'tile servers'.

## What is a Tile Server?

A tile server is a server accessible on the Internet by everyone, or by only people holding the correct API key.

There are four main types of server configuration, two of which are used together by any server: WMS or WMTS & vector or raster. This wiki will focus on WMTS raster servers, such as the main OpenStreetMaps server, as it is the most commonly used option and is easier to setup and explain for beginners, but you can read about the [options for WMS](/miscellaneous/wms-servers) later on in this wiki. At the moment, [support of vector tiles](/miscellaneous/vector-tiles) is limited, but experimental functionality can be added through a [community maintained plugin](/plugins/list).

Simplified, the server holds multiple images (usually in .png format) in a directory structure that looks something like this: '/zoom/x/y.png', which is known as the 'Slippy Map' convention (read more below). These images put together make up the whole world, or area that that tile server supports. In fact, the entire planet (compressed) takes up over 1400 GB! However, one tile is usually really small, under 20KB.

The main tile server that's free to use and open-source is the Open Street Maps tile server, as mentioned above, a server which provides access to millions of tiles covering the whole Earth. that get updated and maintained by the general public.

## 'Slippy Map' Convention

 > '/zoom/x/y.png' or '/x/y/zoom.png'
 >
 > [wiki.openstreetmap.org/wiki/Slippy_map_tilenames](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)

You may also see '/?x={x}&y={y}&zoom={z}', which isn't quite the same as the Slippy Map convention, but it works in essentially the same way, so the below article still applies.

### Zoom

Zoom refers to the zoom level. 1 is the lowest zoom level and contains the whole world in one tile. The higher the number, the more the zoom, and the more the detail, and therefore the less space covered. You can read more about this at [wiki.openstreetmap.org/wiki/Zoom_levels](https://wiki.openstreetmap.org/wiki/Zoom_levels).
Note that many tile servers will not support past a zoom level of 18. Open Street Maps supports up to level 20.

### X & Y

X and Y are values corresponding to the longitude and latitude of a location, however they are not actual longitude and latitude. See [wiki.openstreetmap.org/wiki/Slippy_map_tilenames](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Implementations).

![Lat/Lng to x/y/z](https://wiki.openstreetmap.org/w/images/thumb/a/a5/Latlon_to_tile.png/450px-Latlon_to_tile.png)

![x/y/z to Lat/Lng](https://wiki.openstreetmap.org/w/images/thumb/1/1f/Tile_to_latlon.png/450px-Tile_to_latlon.png)

These images show the mathematics required to convert between Latitude and Longitude & the x/y/z format and vice-versa respectively. All credit goes to Open Street Maps.

## Tile Providers

In this `flutter_map` package, the classes that conduct this maths to get these tiles are called 'tile providers'.

However, these do a lot more than just the maths. They do the maths, format the appropriate URL, potentially stagger the URL (not to get rate limited by the browser or engine), make the request, get the image, process (and potentially store) the image and finally give it back to the main process to paint onto the map for the user to see.

Unless you choose to make your own custom tile provider ([the guide for which can be found here](http://localhost:3000/plugins/how-to-make-a-plugin#where-a-new-layer-is-not-created)), you should never need to handle this yourself.

## Map Layers

Once the tile provider has dealt with the tile, it sends it to a map layer to get painted onto the map. This can be done using canvases, or, in the case of `flutter_map`, Flutter widgets.

The map layers handles user interaction, such as panning, zooming, rotating and tapping.
