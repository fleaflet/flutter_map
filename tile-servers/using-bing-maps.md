# Using Bing Maps

{% hint style="info" %}
'flutter\_map' is in no way associated or related with Bing Maps.

Bing Maps' home page: [microsoft.com/maps](https://www.microsoft.com/maps/)
{% endhint %}

To display map tiles from Bing Maps, a little more effort is needed, as they use a RESTful API with quadkeys, rather than the standard slippy map system.

Luckily, we've constructed all the code you should need below! Feel free to copy and paste into your projects.

{% hint style="info" %}
Thanks to [Luka Glušica](https://github.com/luka-glusica) for discovering the [basic initial implementation](https://github.com/fleaflet/flutter\_map/issues/1197#issuecomment-1478763824).
{% endhint %}

{% hint style="warning" %}
Attribution is not demonstrated here, but may be required. Ensure you comply with Bing Maps' ToS.
{% endhint %}

{% code title="bing_maps.dart" overflow="wrap" lineNumbers="true" %}
```dart
// All compatible imagery sets
enum BingMapsImagerySet {
  road('RoadOnDemand', zoomBounds: (min: 0, max: 21)),
  aerial('Aerial', zoomBounds: (min: 0, max: 20)),
  aerialLabels('AerialWithLabelsOnDemand', zoomBounds: (min: 0, max: 20)),
  canvasDark('CanvasDark', zoomBounds: (min: 0, max: 21)),
  canvasLight('CanvasLight', zoomBounds: (min: 0, max: 21)),
  canvasGray('CanvasGray', zoomBounds: (min: 0, max: 21)),
  ordnanceSurvey('OrdnanceSurvey', zoomBounds: (min: 12, max: 17));

  final String urlValue;
  final ({int min, int max}) zoomBounds;

  const BingMapsImagerySet(this.urlValue, {required this.zoomBounds});
}

// Custom tile provider that contains the quadkeys logic
// Note that you can also extend from the CancellableNetworkTileProvider
class BingMapsTileProvider extends NetworkTileProvider {
  BingMapsTileProvider({super.headers});

  String _getQuadKey(int x, int y, int z) {
    final quadKey = StringBuffer();
    for (int i = z; i > 0; i--) {
      int digit = 0;
      final int mask = 1 << (i - 1);
      if ((x & mask) != 0) digit++;
      if ((y & mask) != 0) digit += 2;
      quadKey.write(digit);
    }
    return quadKey.toString();
  }

  @override
  Map<String, String> generateReplacementMap(
    String urlTemplate,
    TileCoordinates coordinates,
    TileLayer options,
  ) =>
      super.generateReplacementMap(urlTemplate, coordinates, options)
        ..addAll(
          {
            'culture': 'en-GB', // Or your culture value of choice
            'subdomain': options.subdomains[
                (coordinates.x + coordinates.y) % options.subdomains.length],
            'quadkey': _getQuadKey(coordinates.x, coordinates.y, coordinates.z),
          },
        );
}

// Custom `TileLayer` wrapper that can be inserted into a `FlutterMap`
class BingMapsTileLayer extends StatelessWidget {
  const BingMapsTileLayer({
    super.key,
    required this.apiKey,
    required this.imagerySet,
  });

  final String apiKey;
  final BingMapsImagerySet imagerySet;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: http.get(
        Uri.parse(
          'http://dev.virtualearth.net/REST/V1/Imagery/Metadata/${imagerySet.urlValue}?output=json&include=ImageryProviders&key=$apiKey',
        ),
      ),
      builder: (context, response) {
        if (response.data == null) return const Placeholder();

        return TileLayer(
          urlTemplate: (((((jsonDecode(response.data!.body)
                          as Map<String, dynamic>)['resourceSets']
                      as List<dynamic>)[0] as Map<String, dynamic>)['resources']
                  as List<dynamic>)[0] as Map<String, dynamic>)['imageUrl']
              as String,
          tileProvider: BingMapsTileProvider(),
          subdomains: const ['t0', 't1', 't2', 't3'],
          minNativeZoom: imagerySet.zoomBounds.min,
          maxNativeZoom: imagerySet.zoomBounds.max,
        );
      },
    );
  }
}
```
{% endcode %}
