import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class PolylinePage extends StatefulWidget {
  static const String route = 'polyline';

  const PolylinePage({Key? key}) : super(key: key);

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  late Future<List<Polyline>> polylines;

  Future<List<Polyline>> getPolylines() async {
    var polyLines = [
      Polyline(
        points: [
          LatLng(50.5, -0.09),
          LatLng(51.3498, -6.2603),
          LatLng(53.8566, 2.3522),
        ],
        strokeWidth: 4.0,
        color: Colors.amber,
      ),
    ];
    await Future.delayed(const Duration(seconds: 3));
    return polyLines;
  }

  @override
  void initState() {
    polylines = getPolylines();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var points = <LatLng>[
      LatLng(51.5, -0.09),
      LatLng(53.3498, -6.2603),
      LatLng(48.8566, 2.3522),
    ];

    var pointsGradient = <LatLng>[
      LatLng(55.5, -0.09),
      LatLng(54.3498, -6.2603),
      LatLng(52.8566, 2.3522),
    ];

    return Scaffold(
        appBar: AppBar(title: const Text('Polylines')),
        drawer: buildDrawer(context, PolylinePage.route),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Polyline>>(
            future: polylines,
            builder:
                (BuildContext context, AsyncSnapshot<List<Polyline>> snapshot) {
              debugPrint('snapshot: ${snapshot.hasData}');
              if (snapshot.hasData) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text('Polylines'),
                    ),
                    Flexible(
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(51.5, -0.09),
                          zoom: 5.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              debugPrint('onTap');
                              polylines = getPolylines();
                            });
                          },
                        ),
                        layers: [
                          TileLayerOptions(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: ['a', 'b', 'c']),
                          PolylineLayerOptions(
                            polylines: [
                              Polyline(
                                  points: points,
                                  strokeWidth: 4.0,
                                  color: Colors.purple),
                            ],
                          ),
                          PolylineLayerOptions(
                            polylines: [
                              Polyline(
                                points: pointsGradient,
                                strokeWidth: 4.0,
                                gradientColors: [
                                  const Color(0xffE40203),
                                  const Color(0xffFEED00),
                                  const Color(0xff007E2D),
                                ],
                              ),
                            ],
                          ),
                          PolylineLayerOptions(
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
