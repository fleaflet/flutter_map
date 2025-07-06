# Modern Tile Layer

The modern tile layer is a rework of the original tile layer which:

* should be significantly more flexible (-> provide better integration support for plugins)
* resolve some hard-to-debug bugs
* improve performance in the default case

It does this by:

* splitting the logic of the current `TileLayer` & `TileProvider` into 3-5 parts:
  * `BaseTileLayer`: responsible for tile management (initial workings provided by @mootw)

  * a tile loader: responsible for getting the data for individual tiles given the coordinates from the manager  
    In the default implementation, this is further split:
    * a source generator: responsible for telling the source fetcher what to fetch for the tile
    * a source fetcher: responsible for actually fetching the tile data

  * a tile renderer: responsible for painting tiled data

* using a canvas implementation for the default raster tile layer

Significant uestions remaining:

* Is the default tile loader setup (with two stages) too much frameworking/overly-complicated?
* Should the default tile loader have a third step to statically tie the loader more closely to the renderer?
* Simulating retina mode affects all parts of the system - but only (conceptually/for reasoning) applies to raster tiles (although technically it's no different to a top layer option). How should this be represented?
* How far do we want to provide pre-builts? The raster tile layer boils down to 4 parts - a prebuilt is great for beginners, but providing flexbility at this level basically just makes the raster tile layer pre-build a very loose cover for the underlying base tile layer configuration.
* What should the top-level options be (`TileLayerOptions`)? See also retina mode simulation.
* Who's responsibility is enforcing the max-zoom level? Is max-zoom = native max-zoom or MapOptions.maxZoom?

This new functionality has no deadline or estimated completion date - although it's something we've been wanting to do for a while, and we have some work in the
background which may be integrating with this.

Contribution greatly appriciated!
