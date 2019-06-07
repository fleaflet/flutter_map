[![Patreon](https://img.shields.io/badge/patreon-donate-blue.svg)](https://www.patreon.com/johnpryan)

# flutter_map

**Experimental**

A Dart implementation of [Leaflet] for Flutter apps.

[Video](https://drive.google.com/file/d/14srd4ERdgRr68TtLmG6Aho9L1pGOyFF7/view?usp=sharing)

![Screenshot](https://i.imgur.com/I84kptO.png)

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

### Run the example

See the `example/` folder for a working example app.

To run it, in a terminal cd into the folder.
Then execute `ulimit -S -n 2048` ([ref](https://github.com/trentpiercy/trace/issues/1#issuecomment-404494469)).
Then execute `flutter run` with a running emulator.

## Mapbox Tiles

You can use map tiles from a number of
[free and paid map suppliers](http://leafletjs.com/plugins.html#basemap-providers),
or you can host your own map tiles.

The example uses OpenStreetMap tiles, which are free but can be slow.

Use TileLayerOptions to configure other tile providers, such as [mapbox]:

```dart
Widget build(ctx) {
  return TileLayerOptions(
    urlTemplate: "https://api.mapbox.com/v4/"
        "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
    additionalOptions: {
      'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
      'id': 'mapbox.streets',
    },
  );
}
```

To use, you'll need a mapbox key:

1. Create a [Mapbox] account to get an API key
2. Open `leaflet_flutter_example/lib/main.dart` and paste the API key into the
`additionalOptions` map


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
See the `flutter_map_example/` folder for a working example.<br>

Note that there is also `FileTileProvider()`, which you can use to load tiles from the filesystem.

## Plugins

- [flutter_map_marker_cluster](https://github.com/lpongetti/flutter_map_marker_cluster): Provides Beautiful Animated Marker Clustering functionality


## Roadmap

For the latest roadmap, please see the [Issue Tracker]

[Leaflet]: http://leafletjs.com/
[Mapbox]: https://www.mapbox.com/
[Issue Tracker]: https://github.com/apptreesoftware/flutter_map/issues
