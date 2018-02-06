# flutter_map

**Experimental**

A flutter implementation of [leaflet].

[Video](https://drive.google.com/file/d/14srd4ERdgRr68TtLmG6Aho9L1pGOyFF7/view?usp=sharing)

![Screenshot](https://i.imgur.com/10mBN86.png)

## Usage

Add flutter_map to your pubspec:

```yaml
dependencies:
  flutter_map: ^0.0.1
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

see the `flutter_map_example/` folder for a working example app.

## Running the Example

To use, you'll need a mapbox key:

1. Create a [mapbox] account to get an api key
2. open leaflet_flutter_example/lib/main.dart and paste the API key into the
`additionalOptions` map.

[leaflet]: http://leafletjs.com/
[mapbox]: https://www.mapbox.com/
