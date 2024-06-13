import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class MapControllerPage extends StatefulWidget {
  static const String route = 'map_controller';

  const MapControllerPage({super.key});

  @override
  MapControllerPageState createState() => MapControllerPageState();
}

class MapControllerPageState extends State<MapControllerPage> {
  /// This example uses a global MapController instance to test if the
  /// controller can get applied to the map multiple times.
  static final MapController _mapController = MapController();

  double _rotation = 0;

  static const _london = LatLng(51.5, -0.09);
  static const _paris = LatLng(48.8566, 2.3522);
  static const _dublin = LatLng(53.3498, -6.2603);

  static const _markers = [
    Marker(
      width: 80,
      height: 80,
      point: _london,
      child: FlutterLogo(key: ValueKey('blue')),
    ),
    Marker(
      width: 80,
      height: 80,
      point: _dublin,
      child: FlutterLogo(key: ValueKey('green')),
    ),
    Marker(
      width: 80,
      height: 80,
      point: _paris,
      child: FlutterLogo(key: ValueKey('purple')),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MapController')),
      drawer: const MenuDrawer(MapControllerPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () => _mapController.move(_london, 18),
                    child: const Text('London'),
                  ),
                  MaterialButton(
                    onPressed: () => _mapController.move(_paris, 5),
                    child: const Text('Paris'),
                  ),
                  MaterialButton(
                    onPressed: () => _mapController.move(_dublin, 5),
                    child: const Text('Dublin'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () {
                      final bounds = LatLngBounds.fromPoints([
                        _dublin,
                        _paris,
                        _london,
                      ]);

                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      );
                    },
                    child: const Text('Fit Bounds'),
                  ),
                  Builder(builder: (context) {
                    return MaterialButton(
                      onPressed: () {
                        final bounds = _mapController.camera.visibleBounds;

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Map bounds: \n'
                            'E: ${bounds.east} \n'
                            'N: ${bounds.north} \n'
                            'W: ${bounds.west} \n'
                            'S: ${bounds.south}',
                          ),
                        ));
                      },
                      child: const Text('Get Bounds'),
                    );
                  }),
                  const Text('Rotation:'),
                  Expanded(
                    child: Slider(
                      value: _rotation,
                      min: 0,
                      max: 360,
                      onChanged: (degree) {
                        setState(() {
                          _rotation = degree;
                        });
                        _mapController.rotate(degree);
                      },
                    ),
                  )
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 5,
                  maxZoom: 5,
                  minZoom: 3,
                ),
                children: [
                  openStreetMapTileLayer,
                  const MarkerLayer(markers: _markers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
