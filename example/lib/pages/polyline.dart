import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class PolylinePage extends StatefulWidget {
  static const String route = 'polyline';

  const PolylinePage({Key? key}) : super(key: key);

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  late Future<List<Polyline>> polylines;

  Future<List<Polyline>> getPolylines() async {
    final polyLines = <Polyline>[
      Polyline(
        points: [
          LatLng(50.5, -0.09),
          LatLng(51.3498, -6.2603),
          LatLng(53.8566, 2.3522),
        ],
        strokeWidth: 20,
        color: Colors.blue.withOpacity(0.6),
        borderStrokeWidth: 20,
        borderColor: Colors.red.withOpacity(0.4),
      ),
      Polyline(
        points: [
          LatLng(50.2, -0.08),
          LatLng(51.2498, -7.2603),
          LatLng(54.8566, 1.3522),
        ],
        strokeWidth: 20,
        color: Colors.black.withOpacity(0.2),
        borderStrokeWidth: 20,
        borderColor: Colors.white30,
      ),
      Polyline(
        points: [
          LatLng(49.1, -0.06),
          LatLng(51.15, -7.4),
          LatLng(55.5, 0.8),
        ],
        strokeWidth: 10,
        color: Colors.yellow,
        borderStrokeWidth: 10,
        borderColor: Colors.blue.withOpacity(0.5),
      ),
      Polyline(
        points: [
          LatLng(48.1, -0.03),
          LatLng(50.5, -7.8),
          LatLng(56.5, 0.4),
        ],
        strokeWidth: 10,
        color: Colors.amber,
        borderStrokeWidth: 10,
        borderColor: Colors.blue.withOpacity(0.5),
      ),
    ];
    await Future<void>.delayed(const Duration(seconds: 3));
    return polyLines;
  }

  @override
  void initState() {
    polylines = getPolylines();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[
      LatLng(51.5, -0.09),
      LatLng(53.3498, -6.2603),
      LatLng(48.8566, 2.3522),
    ];

    final pointsGradient = <LatLng>[
      LatLng(55.5, -0.09),
      LatLng(54.3498, -6.2603),
      LatLng(52.8566, 2.3522),
    ];

    return Scaffold(
        appBar: AppBar(title: const Text('Polylines')),
        drawer: buildDrawer(context, PolylinePage.route),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: FutureBuilder<List<Polyline>>(
            future: polylines,
            builder:
                (BuildContext context, AsyncSnapshot<List<Polyline>> snapshot) {
              debugPrint('snapshot: ${snapshot.hasData}');
              if (snapshot.hasData) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Text('Polylines'),
                    ),
                    Flexible(
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(51.5, -0.09),
                          zoom: 5,
                          onTap: (tapPosition, point) {
                            setState(() {
                              debugPrint('onTap');
                              polylines = getPolylines();
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'dev.fleaflet.flutter_map.example',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                  points: points,
                                  strokeWidth: 4,
                                  color: Colors.purple),
                            ],
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: pointsGradient,
                                strokeWidth: 4,
                                gradientColors: [
                                  const Color(0xffE40203),
                                  const Color(0xffFEED00),
                                  const Color(0xff007E2D),
                                ],
                              ),
                            ],
                          ),
                          PolylineLayer(
                            polylines: snapshot.data!,
                            polylineCulling: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const Text(
                  'Getting map data...\n\nTap on map when complete to refresh map data.');
            },
          ),
        ));
  }
}
