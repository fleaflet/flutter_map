# Plugins List

There are many independently maintained 'plugins' created by the 'flutter\_map' community that give extra, prebuilt functionality, saving you even more time and potentially money.

{% hint style="danger" %}
Although these plugins have been checked by 'flutter\_map' maintainers, we do not accept responsibility for any issues or threats posed by independently maintained plugins.

Use plugins at your own risk.
{% endhint %}

{% hint style="warning" %}
There is no guarantee that any of these plugins will support the latest version of flutter\_map.

Please remain patient with the plugin authors/owners.
{% endhint %}

Some pages in this documentation provide direct links to these plugins to make it easier for you to find a suitable plugin. However, if you're just browsing, a full list is provided below (in no particular order), containing many of the available plugins. You can click on any of the tiles to visit it's GitHub repo.

## Miscellaneous

From more layers to whole heaps of new functionality, it's all here - assuming it's not in one of the other sections!

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_tile_caching (JaffaKetchup)</strong></td><td>Advanced and highly-configurable caching solution, with support for bulk downloading</td><td><a href="https://github.com/JaffaKetchup/flutter_map_tile_caching">https://github.com/JaffaKetchup/flutter_map_tile_caching</a></td></tr><tr><td><strong>vector_map_tiles (greensopinion)</strong></td><td>Suite of tools and layers for working with vector maps and style files</td><td><a href="https://github.com/greensopinion/flutter-vector-map-tiles">https://github.com/greensopinion/flutter-vector-map-tiles</a></td></tr><tr><td><strong>lat_lon_grid_plugin (matthiasdittmer)</strong></td><td>A latitude longitude grid layer/overlay</td><td><a href="https://github.com/matthiasdittmer/lat_lon_grid_plugin">https://github.com/matthiasdittmer/lat_lon_grid_plugin</a></td></tr><tr><td><em></em><a data-footnote-ref href="#user-content-fn-1"><em>BETA</em></a> <strong>flutter_osrm (JaffaKetchup)</strong></td><td>Suite of tools for working with routing information from an OSRM server</td><td></td></tr><tr><td><strong>flutter_map_geojson (jozes)</strong></td><td>Suite of tools to parse data in the GeoJson format into map features</td><td><a href="https://github.com/jozes/flutter_map_geojson">https://github.com/jozes/flutter_map_geojson</a></td></tr><tr><td><strong>flutter_map_animations (TesteurManiak)</strong></td><td>Replacement for <code>MapController</code> which provides animated movement alternatives</td><td><a href="https://github.com/TesteurManiak/flutter_map_animations">https://github.com/TesteurManiak/flutter_map_animations</a></td></tr></tbody></table>

## Marker Clustering

Marker clustering groups markers together under bigger markers when zoomed further out, decluttering your UI and giving a performance boost.

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_supercluster (rorystephenson)</strong></td><td>Superfast™ marker clustering solution, without animations</td><td><a href="https://github.com/rorystephenson/flutter_map_supercluster">https://github.com/rorystephenson/flutter_map_supercluster</a></td></tr><tr><td><strong>flutter_map_marker_cluster (lpongetti)</strong></td><td>Beautiful and animated marker clustering solution</td><td><a href="https://github.com/lpongetti/flutter_map_marker_cluster">https://github.com/lpongetti/flutter_map_marker_cluster</a></td></tr><tr><td><strong>flutter_map_radius_cluster (rorystephenson)</strong></td><td>Marker clustering solution with support for <code>async</code> marker searching within a radius</td><td><a href="https://github.com/rorystephenson/flutter_map_radius_cluster">https://github.com/rorystephenson/flutter_map_radius_cluster</a></td></tr></tbody></table>

## Better `Marker`s

We thought our built in `Marker`s were pretty good! But it turns out, the community thinks there's a lot more that can be done with them.

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_location_marker (tlserver)</strong></td><td>Provides a prebuilt solution to display the user's location and heading/direction</td><td><a href="https://github.com/tlserver/flutter_map_location_marker">https://github.com/tlserver/flutter_map_location_marker</a></td></tr><tr><td><strong>flutter_map_marker_popup (rorystephenson)</strong></td><td>Provides a prebuilt solution to display a popup above a marker when tapped</td><td><a href="https://github.com/rorystephenson/flutter_map_marker_popup">https://github.com/rorystephenson/flutter_map_marker_popup</a></td></tr><tr><td><strong>flutter_map_floating_marker_titles (androidseb)</strong></td><td>Enables the display of 'floating' titles over markers</td><td><a href="https://github.com/androidseb/flutter_map_floating_marker_titles">https://github.com/androidseb/flutter_map_floating_marker_titles</a></td></tr><tr><td><em></em><a data-footnote-ref href="#user-content-fn-2"><em>BETA</em></a> <strong>flutter_map_fast_markers (KanarekApp)</strong></td><td>Improves performance of markers by painting directly onto canvas</td><td><a href="https://github.com/KanarekApp/flutter_map_fast_markers/tree/canary">https://github.com/KanarekApp/flutter_map_fast_markers/tree/canary</a></td></tr></tbody></table>

## Better `Polyline`s & `Polygon`s

Need more advanced `Polyline`/`Polygon` functionality? These are for you.

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_line_editor (ibrierley)</strong></td><td>Enables better dynamic editing of <code>Polyline</code>s and <code>Polygon</code>s</td><td><a href="https://github.com/ibrierley/flutter_map_line_editor">https://github.com/ibrierley/flutter_map_line_editor</a></td></tr><tr><td><strong>line_animator (ibrierley)</strong></td><td>Interpolates along a set of points, allowing gradual drawing of lines and animating moving markers</td><td><a href="https://github.com/ibrierley/line_animator">https://github.com/ibrierley/line_animator</a></td></tr><tr><td><strong>flutter_map_tappable_polyline (OwnWeb)</strong></td><td>Provides an <code>onTap</code> callback for <code>Polyline</code>s</td><td><a href="https://github.com/OwnWeb/flutter_map_tappable_polyline">https://github.com/OwnWeb/flutter_map_tappable_polyline</a></td></tr></tbody></table>

[^1]: This plugin is not ready for production use, and is liable to breaking changes without major version increments!

[^2]: This plugin is not ready for production use, and is liable to breaking changes without major version increments!
