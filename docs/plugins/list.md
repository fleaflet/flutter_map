---
id: list
sidebar_position: 1
---

# Plugins List

There are many independently maintained 'plugins' created by the 'flutter_map' community that give extra, prebuilt functionality, saving you even more time and potentially money.

:::danger Limited Responsibility
Although these plugins have been checked by 'flutter_map' maintainers, 'flutter_map' maintainers do not accept responsibility for any issues or threats posed by independently maintained plugins. Use plugins at your own risk.
:::

Some pages in this documentation provide direct links to these plugins, where appropriate, to make it easier for you to find a suitable plugin. Note that the above warning applies to those links as well.

However, if you're just browsing, a list is provided below (in no particular order), containing many of the open-source plugins, each with a short description by the author saying what the plugin does/what it's useful for:

## Full List

- [`flutter_map_tile_caching`](https://github.com/JaffaKetchup/flutter_map_tile_caching) by [JaffaKetchup](https://github.com/JaffaKetchup)  
Provides advanced caching functionality, with ability to download map regions for offline use

- [`flutter_map_marker_cluster`](https://github.com/lpongetti/flutter_map_marker_cluster) by [lpongetti](https://github.com/lpongetti)  
Provides beautiful and animated marker clustering functionality

- [`vector_map_tiles`](https://github.com/greensopinion/flutter-vector-map-tiles) by [greensopinion](https://github.com/greensopinion)  
Enables the use of vector and 'mixed' tiles (see the [Raster vs Vector Tiles page](/servers/raster-vs-vector-tiles))

- [`flutter_map_line_editor`](https://github.com/ibrierley/flutter_map_line_editor) by [ibrierley](https://github.com/ibrierley)  
Enables creation/editing of `Polyline`s and `Polygon`s

- [`flutter_map_location_marker`](https://github.com/tlserver/flutter_map_location_marker) by [tlserver](https://github.com/tlserver)  
Displays the user's location and heading

- [`flutter_map_marker_popup`](https://github.com/rorystephenson/flutter_map_marker_popup) by [rorystephenson](https://github.com/rorystephenson)  
Displays customisable pop-ups for markers

- [`map_elevation`](https://github.com/OwnWeb/map_elevation) by [OwnWeb](https://github.com/OwnWeb)  
Displays the elevation of a polyline, like `Leaflet.Elevation`

- [`flutter_map_floating_marker_titles`](https://github.com/androidseb/flutter_map_floating_marker_titles) by [androidseb](https://github.com/androidseb)  
Displays floating marker titles on the map view

- [`flutter_map_tappable_polyline`](https://github.com/OwnWeb/flutter_map_tappable_polyline) by [OwnWeb](https://github.com/OwnWeb)  
Adds an `onTap` callback to `Polyline`

- [`flutter_map_dragmarker`](https://github.com/ibrierley/flutter_map_dragmarker) by [ibrierley](https://github.com/ibrierley)  
Adds a movable/draggable marker

- [`flutter_map_move_marker`](https://github.com/StrangeYear/flutter_map_move_marker) by [StrangeYear](https://github.com/StrangeYear)  
Adds a movable/draggable marker

- [`lat_lon_grid_plugin`](https://github.com/matthiasdittmer/lat_lon_grid_plugin) by [matthiasdittmer](https://github.com/matthiasdittmer)  
Adds a latitude/longitude grid overlay to maps

- _DEPRECATED_ [`flutter_map_location`](https://github.com/Xennis/flutter_map_location) by [Xennis](https://github.com/Xennis)

:::info Related Libraries
Note that useful libraries that may be used with 'flutter_map' but are not specifically for 'flutter_map' are not listed here. These are instead mentioned and linked to in appropriate places throughout other documentation pages.
:::

## Submitting A New Plugin

If you've made your own plugin that you're willing to share, you can add it to this list by creating a pull request in GitHub. We're always looking forward to see what you've made!

When submitting a plugin & PR, please ensure the plugin:

- _preferably_ includes 'flutter\_map\_' in the name
- _preferably_ available via a pub.dev installation
- has good documentation (information for installation and basic setup/functionality)
- includes a runnable example and/or screenshots/screen-recordings
- has a description that accurately and concisely represents your plugin

If you want to provide extra assistance to your users in a shared space, consider the official 'flutter_map' Discord server! Join using the button at the top of this page, and ping '@Github Maintainer' to be added to the 'Plugin Owner' role. You can then be easily identified and provide help or announcements in a dedicated plugins channel.
