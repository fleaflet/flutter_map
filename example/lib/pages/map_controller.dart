import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class MapControllerPage extends StatefulWidget {
  static const String route = 'map_controller';

  const MapControllerPage({Key? key}) : super(key: key);

  @override
  MapControllerPageState createState() {
    return MapControllerPageState();
  }
}

const LatLng london = LatLng(51.5, -0.09);
const LatLng paris = LatLng(48.8566, 2.3522);
const LatLng dublin = LatLng(53.3498, -6.2603);

class MapControllerPageState extends State<MapControllerPage> {
  late final MapController _mapController;
  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        width: 80,
        height: 80,
        point: london,
        builder: (ctx) => Container(
          key: const Key('blue'),
          child: const FlutterLogo(),
        ),
      ),
      Marker(
        width: 80,
        height: 80,
        point: dublin,
        builder: (ctx) => const FlutterLogo(
          key: Key('green'),
          textColor: Colors.green,
        ),
      ),
      Marker(
        width: 80,
        height: 80,
        point: paris,
        builder: (ctx) => Container(
          key: const Key('purple'),
          child: const FlutterLogo(textColor: Colors.purple),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MapController')),
      drawer: buildDrawer(context, MapControllerPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () {
                      _mapController.move(london, 18);
                    },
                    child: const Text('London'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      _mapController.move(paris, 5);
                    },
                    child: const Text('Paris'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      _mapController.move(dublin, 5);
                    },
                    child: const Text('Dublin'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () {
                      final bounds = LatLngBounds.fromPoints([
                        dublin,
                        paris,
                        london,
                      ]);

                      _mapController.fitCamera(
                        FitBounds(
                          bounds: bounds,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      );
                    },
                    child: const Text('Fit Bounds'),
                  ),
                  Builder(builder: (BuildContext context) {
                    return MaterialButton(
                      onPressed: () {
                        final bounds = _mapController.mapCamera.visibleBounds;

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
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
