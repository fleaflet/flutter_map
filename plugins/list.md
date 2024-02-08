# Plugins List

There are many independently maintained 'plugins' created by the 'flutter\_map' community that give extra, prebuilt functionality, saving you even more time and potentially money.

Some pages in this documentation provide direct links to these plugins to make it easier for you to find a suitable plugin.

However, if you're just browsing, a full list is provided below (in no particular order), containing many of the available plugins. You can click on any of the tiles to visit its GitHub repo or pub.dev package.

{% hint style="danger" %}
Although these plugins have been checked by 'flutter\_map' maintainers, we do not accept responsibility for any issues or threats posed by independently maintained plugins.

Use plugins at your own risk.
{% endhint %}

{% hint style="warning" %}
There is no guarantee that any of these plugins will support the latest version of flutter\_map. Please remain patient with the plugin authors/owners.
{% endhint %}

{% hint style="info" %}
Many plugins provide multiple methods to achieve similar goals. It is recommended to read the documentation of each potential plugin before using it in your project, as they might have slightly different feature sets or stability.
{% endhint %}

## Tools

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_animations (TesteurManiak)</strong></td><td>Replacement <code>MapController</code> which provides animated movement alternatives</td><td><a href="https://github.com/TesteurManiak/flutter_map_animations">https://github.com/TesteurManiak/flutter_map_animations</a></td></tr><tr><td><strong>flutter_map_geojson (jozes)</strong></td><td>Parse GeoJson data and transform into map features</td><td><a href="https://github.com/jozes/flutter_map_geojson">https://github.com/jozes/flutter_map_geojson</a></td></tr><tr><td><a data-footnote-ref href="#user-content-fn-1"><em>BETA</em></a> <strong>geojson_vector_slicer (ibrierley)</strong></td><td>Display GeoJson using sliced vector tiles, and a suite of other tools</td><td><a href="https://github.com/ibrierley/geojson_vector_slicer">https://github.com/ibrierley/geojson_vector_slicer</a></td></tr><tr><td><a data-footnote-ref href="#user-content-fn-2"><em>BETA</em></a> <strong>flutter_osrm (JaffaKetchup)</strong></td><td>Query an OSRM-based server to provide routing and other related functionality</td><td><a href="https://github.com/JaffaKetchup/flutter_osrm">https://github.com/JaffaKetchup/flutter_osrm</a></td></tr><tr><td><a data-footnote-ref href="#user-content-fn-3"><em>BETA</em></a> <strong>flutter_map_query_osm_features (JaffaKetchup)</strong></td><td>Query OpenStreetMap features within a radius of a point, using the Overpass and OSM APIs</td><td><a href="https://github.com/JaffaKetchup/flutter_map_query_osm_features">https://github.com/JaffaKetchup/flutter_map_query_osm_features</a></td></tr></tbody></table>

### External

These are not necessarily purpose built for flutter\_map, but could be very useful for some applications for related purposes.

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>dart_earcut (JaffaKetchup)</strong></td><td>Performant earclipping triangulation algorithm, ported from the Mapbox project by the same name</td><td><a href="https://github.com/JaffaKetchup/dart_earcut">https://github.com/JaffaKetchup/dart_earcut</a></td></tr><tr><td><strong>polybool (mohammedX6)</strong></td><td>Suite of tools to operate on polygons, such as union, intersection, and difference</td><td><a href="https://github.com/mohammedX6/poly_bool_dart">https://github.com/mohammedX6/poly_bool_dart</a></td></tr></tbody></table>

## Additional Layers

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>vector_map_tiles (greensopinion)</strong></td><td>Suite of tools and layers for working with vector maps and associated style files</td><td><a href="https://github.com/greensopinion/flutter-vector-map-tiles">https://github.com/greensopinion/flutter-vector-map-tiles</a></td></tr><tr><td><strong>flutter_map_polywidget (TimBaumgart)</strong></td><td>Layer that allows any widget to be displayed inside a positioned box, similar to <a data-mention href="../layers/overlay-image-layer.md">overlay-image-layer.md</a></td><td><a href="https://pub.dev/packages/flutter_map_polywidget">https://pub.dev/packages/flutter_map_polywidget</a></td></tr><tr><td><strong>fluttermap_heatmap (tprebs)</strong></td><td>Layer that represents multiple data points in a density-to-color relationship</td><td><a href="https://github.com/tprebs/fluttermap_heatmap">https://github.com/tprebs/fluttermap_heatmap</a></td></tr><tr><td><strong>lat_lon_grid_plugin (matthiasdittmer)</strong></td><td>Layer that shows a grid of latitude longitude lines</td><td><a href="https://github.com/matthiasdittmer/lat_lon_grid_plugin">https://github.com/matthiasdittmer/lat_lon_grid_plugin</a></td></tr></tbody></table>

## Offline Mapping

To help choose between one of these plugins or a DIY solution, see:

{% content-ref url="../tile-servers/offline-mapping.md" %}
[offline-mapping.md](../tile-servers/offline-mapping.md)
{% endcontent-ref %}



<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_tile_caching (JaffaKetchup)</strong></td><td>Advanced, performant, highly configurable caching &#x26; bulk downloading (under a GPL license)</td><td><a href="https://github.com/JaffaKetchup/flutter_map_tile_caching">https://github.com/JaffaKetchup/flutter_map_tile_caching</a></td></tr><tr><td><strong>flutter_map_cache (josxha)</strong></td><td>Lightweight tile caching with support for most storage backends and request cancellation.</td><td><a href="https://github.com/josxha/flutter_map_plugins/tree/main/flutter_map_cache">https://github.com/josxha/flutter_map_plugins/tree/main/flutter_map_cache</a></td></tr></tbody></table>

## Better `Marker`s

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_location_marker (tlserver)</strong></td><td>Provides a prebuilt solution to display the user's location and heading/direction</td><td><a href="https://github.com/tlserver/flutter_map_location_marker">https://github.com/tlserver/flutter_map_location_marker</a></td></tr><tr><td><strong>flutter_map_marker_popup (rorystephenson)</strong></td><td>Provides a prebuilt solution to display a popup above a marker when tapped</td><td><a href="https://github.com/rorystephenson/flutter_map_marker_popup">https://github.com/rorystephenson/flutter_map_marker_popup</a></td></tr><tr><td><strong>flutter_map_floating_marker_titles (androidseb)</strong></td><td>Enables the display of 'floating' titles over markers</td><td><a href="https://github.com/androidseb/flutter_map_floating_marker_titles">https://github.com/androidseb/flutter_map_floating_marker_titles</a></td></tr><tr><td><a data-footnote-ref href="#user-content-fn-4"><em>BETA</em></a> <strong>flutter_map_fast_markers (KanarekApp)</strong></td><td>Improves performance of markers by painting directly onto canvas</td><td><a href="https://github.com/KanarekApp/flutter_map_fast_markers/tree/canary">https://github.com/KanarekApp/flutter_map_fast_markers/tree/canary</a></td></tr></tbody></table>

### Marker Clustering

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_supercluster (rorystephenson)</strong></td><td>Superfast™ marker clustering solution, without animations</td><td><a href="https://github.com/rorystephenson/flutter_map_supercluster">https://github.com/rorystephenson/flutter_map_supercluster</a></td></tr><tr><td><strong>flutter_map_marker_cluster (lpongetti)</strong></td><td>Beautiful and animated marker clustering solution</td><td><a href="https://github.com/lpongetti/flutter_map_marker_cluster">https://github.com/lpongetti/flutter_map_marker_cluster</a></td></tr><tr><td><strong>flutter_map_radius_cluster (rorystephenson)</strong></td><td>Marker clustering solution with support for <code>async</code> marker searching within a radius</td><td><a href="https://github.com/rorystephenson/flutter_map_radius_cluster">https://github.com/rorystephenson/flutter_map_radius_cluster</a></td></tr></tbody></table>

## Better `Polyline`s & `Polygon`s

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>flutter_map_tappable_polyline (OwnWeb)</strong></td><td>Provides an <code>onTap</code> callback for <code>Polyline</code>s</td><td><a href="https://github.com/OwnWeb/flutter_map_tappable_polyline">https://github.com/OwnWeb/flutter_map_tappable_polyline</a></td></tr><tr><td><strong>flutter_map_line_editor (ibrierley)</strong></td><td>Enables better dynamic editing of <code>Polyline</code>s and <code>Polygon</code>s</td><td><a href="https://github.com/ibrierley/flutter_map_line_editor">https://github.com/ibrierley/flutter_map_line_editor</a></td></tr><tr><td><strong>line_animator (ibrierley)</strong></td><td>Interpolates along a set of points, allowing gradual drawing of lines and animating moving markers</td><td><a href="https://github.com/ibrierley/line_animator">https://github.com/ibrierley/line_animator</a></td></tr></tbody></table>

[^1]: This plugin is not ready for production use, and is liable to breaking changes without major version increments!

[^2]: This plugin is not ready for production use, and is liable to breaking changes without major version increments!

[^3]: This plugin is not ready for production use, and is liable to breaking changes without major version increments!

[^4]: This plugin is not ready for production use, and is liable to breaking changes without major version increments!
