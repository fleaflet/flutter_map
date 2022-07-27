# Raster vs Vector Tiles

{% hint style="info" %}
It is important to note that 'flutter\_map' only supports raster tiles. Vector tiles are currently only supported by a community maintained plugin.

This is described in more detail at the bottom of this page.
{% endhint %}

There are 2 main types of tiles a server can serve: raster and vector; each has their own advantages and drawbacks. This page is designed to help you choose a type for your app, and help you use vector tiles if you choose to.

## Raster Tiles

Raster tiles are the 'older' type of tile, and are raster images (usually .png or .jpg). These tiles are good because they can render quickly and easily, can be viewed without special software, and are readily available from most mapping services. As such, this makes them the popular choice for beginners.

However, raster tiles cannot be easily themed: a theme needs a whole new set of map tiles. This makes apps using light and dark themes have mismatching maps. As well as this, raster tiles usually have larger file sizes meaning slower download times, and they can become blurred/pixelated when viewed at a larger scale: a problem for users when zooming between zoom levels. Another issue is that shapes/text inside tiles cannot be rotated, hence the name 'static tiles': therefore, rotating the map will not rotate the name of a road, for example.

## Vector Tiles

Vector tiles can be considered the 'newer' standard. These images might contain a specialised format (such as .pbf) dictating the mathematics and coordinates used to draw lines and shapes. Because these tiles are drawn at render time instead of at request/server time, theming can be used to make the map fit in better with an app's theme. The math-based image means that the images/tiles can be scaled without any loss of clarity.

However it does add complexity to the rendering process as each element needs to be parsed and painted individually, meaning an impact to performance. Text elements and certain shapes can also be rotated (unlike raster tiles) to match the user's orientation, not the orientation of the map; but calculating this rotation needs to be done every frame, meaning an even larger impact on performance.

### Using Vector Tiles

Due to the complications mentioned above, 'flutter\_map' does not natively support vector tiles. However, you can use an existing [community maintained plugin (`vector_map_tiles`)](https://github.com/greensopinion/flutter-vector-map-tiles) to do this.

The plugin also supports 'mixed' mode to get the best of both worlds: using raster images during animations to improve performance, and vector rendering to provide sharp visuals and custom theming when idle.
