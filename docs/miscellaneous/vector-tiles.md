---
id: vector-tiles
sidebar_position: 3
---

# Vector Tiles

There are 2 main types of tiles a server can serve: raster and vector; each has their own advantages and drawbacks.

Raster tiles serve tiles as raster images, usually .png or .jpg/.jpeg. This makes them easy to get and paint onto a canvas/viewport in Flutter, but has the drawback of potentially having larger file sizes resulting in slower downloads, as well as severely limited customisability. This means a whole map set needs to be created for each theme, such as light and dark theme.

Vector tiles can be considered the 'newer standard'. These solve the issues mentioned above, as each tile can be styled at request or paint time. However it does add complexity to the canvas/viewport painting process as each path/polygon needs to be parsed and rendered. Another drawback is performance: the complex mathematics needed to render the tile (usually) needs to be done every frame, and if not, the previous issue still applies anyway.

Due to these complications, `flutter_map` does not support vector tiles. However, you can use an existing [community maintained plugin](https://github.com/greensopinion/flutter-vector-map-tiles) to do this. The linked plugin also supports 'mixed' mode:

To get the best of both worlds, mixing raster and vector tiles together can be used to provide sharp, customizable visuals when idle or during slow animation, and speed when animating (such as panning, rotating and zooming).
