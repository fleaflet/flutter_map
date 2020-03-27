[![BuildStatus](https://api.travis-ci.org/johnpryan/flutter_map.svg?branch=master)](https://travis-ci.org/johnpryan/flutter_map)
[![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map)

# flutter_map

A Dart implementation of [Leaflet] for Flutter apps.

## Usage

Add flutter_map to your pubspec:

```yaml
dependencies:
  flutter_map: any # or the latest version on Pub
```

Configure the map using `MapOptions` and layer options:

```dart
Widget build(BuildContext context) {
  return new FlutterMap(
    options: new MapOptions(
      center: new LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      new TileLayerOptions(
        urlTemplate: "https://api.tiles.mapbox.com/v4/"
            "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
        additionalOptions: {
          'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
          'id': 'mapbox.streets',
        },
      ),
      new MarkerLayerOptions(
        markers: [
          new Marker(
            width: 80.0,
            height: 80.0,
            point: new LatLng(51.5, -0.09),
            builder: (ctx) =>
            new Container(
              child: new FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
  );
}
```

### Azure Maps provider

Configure the map to use [Azure Maps](https://azure.com/maps) by using the following `MapOptions` and layer options:

```dart
Widget build(BuildContext context) {
  return new FlutterMap(
    options: new MapOptions(
      center: new LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      new TileLayerOptions(
        urlTemplate: "https://atlas.microsoft.com/map/tile/png?api-version=1&layer=basic&style=main&tileSize=256&view=Auto&zoom={z}&x={x}&y={y}&subscription-key={subscriptionKey}",
        additionalOptions: {
          'subscriptionKey': '<YOUR_AZURE_MAPS_SUBSCRIPTON_KEY>'
        },
      ),
      new MarkerLayerOptions(
        markers: [
          new Marker(
            width: 80.0,
            height: 80.0,
            point: new LatLng(51.5, -0.09),
            builder: (ctx) =>
            new Container(
              child: new FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
  );
}
```

To use Azure Maps you will need to [setup an account and get a subscription key](https://docs.microsoft.com/en-us/azure/azure-maps/quick-demo-map-app)

### Open Street Map provider

Configure the map to use [Open Street Map](https://openstreetmap.org) by using the following `MapOptions` and layer options:

```dart
Widget build(BuildContext context) {
  return new FlutterMap(
    options: new MapOptions(
      center: new LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      new TileLayerOptions(
        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        subdomains: ['a', 'b', 'c']
      ),
      new MarkerLayerOptions(
        markers: [
          new Marker(
            width: 80.0,
            height: 80.0,
            point: new LatLng(51.5, -0.09),
            builder: (ctx) =>
            new Container(
              child: new FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
  );
}
```

### Custom CRS

By default flutter_map supports only WGS84 (EPSG:4326) and Google Mercator (EPSG:3857) projections. With the integration of [proj4dart](https://github.com/maRci002/proj4dart) any coordinate reference systems (CRS) can be defined and used.

Define custom CRS:

```dart
var resolutions = <double>[32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128];
var maxZoom = (resolutions.length - 1).toDouble();

var epsg3413CRS = Proj4Crs.fromFactory(
  code: 'EPSG:3413',
  proj4Projection:
      proj4.Projection.add('EPSG:3413', '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'),
  resolutions: resolutions
);
```

Use Custom CRS in map and in WMS layers:

```dart
child: FlutterMap(
  options: MapOptions(
    // Set the map's CRS
    crs: epsg3413CRS,
    center: LatLng(65.05166470332148, -19.171744826394896),
    maxZoom: maxZoom,
  ),
  layers: [
    TileLayerOptions(
      wmsOptions: WMSTileLayerOptions(
        // Set the WMS layer's CRS too
        crs: epsg3413CRS,
        baseUrl: 'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
        layers: ['gebco_north_polar_view'],
      ),
    ),
  ],
);
```

For more details visit [Custom CRS demo page](./example/lib/pages/custom_crs/Readme.md).

## Run the example

See the `example/` folder for a working example app.

To run it, in a terminal cd into the folder.
Then execute `ulimit -S -n 2048` ([ref](https://github.com/trentpiercy/trace/issues/1#issuecomment-404494469)).
Then execute `flutter run` with a running emulator.

## Offline maps

[Follow this guide to grab offline tiles](https://tilemill-project.github.io/tilemill/docs/guides/osm-bright-mac-quickstart/)<br>
Once you have your map exported to `.mbtiles`, you can use [mbtilesToPng](https://github.com/alfanhui/mbtilesToPngs) to unpack into `/{z}/{x}/{y}.png`.
Move this to Assets folder and add asset directories to `pubspec.yaml`. Minimum required fields for offline maps are:

```dart
Widget build(ctx) {
  return FlutterMap(
    options: MapOptions(
      center: LatLng(56.704173, 11.543808),
      zoom: 13.0,
      swPanBoundary: LatLng(56.6877, 11.5089),
      nePanBoundary: LatLng(56.7378, 11.6644),
    ),
    layers: [
      TileLayerOptions(
        tileProvider: AssetTileProvider(),
        urlTemplate: "assets/offlineMap/{z}/{x}/{y}.png",
      ),
    ],
  );
}
```

Make sure PanBoundaries are within offline map boundary to stop missing asset errors.<br>


Note that there is also next classes for offline tiles:
* `FileTileProvider`, which you can use to load tiles from the filesystem;
* `StorageCachingTileProvider`, caches all browsing tiles in local db;
* `TileStorageCachingManager`, manages local tile db. This class
has easy static api for config db size, loading and preloading tiles.
`StorageCachingTileProvider` uses this class under the hood.

See the `flutter_map_example/` folder for a working examples.

## Plugins

- [flutter_map_marker_cluster](https://github.com/lpongetti/flutter_map_marker_cluster): Provides Beautiful Animated Marker Clustering functionality
- [user_location](https://github.com/igaurab/user_location_plugin): A plugin to handle and plot the current user location in FlutterMap

## Roadmap

For the latest roadmap, please see the [Issue Tracker]

[Leaflet]: http://leafletjs.com/
[Mapbox]: https://www.mapbox.com/
[Issue Tracker]: https://github.com/johnpryan/flutter_map/issues
