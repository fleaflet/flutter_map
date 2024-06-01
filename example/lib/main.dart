import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int cnt = 0;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await Future.delayed(const Duration(seconds: 1));
      cnt++;
      setState(() {});
    });
  }

  final bounds = LatLngBounds(
    const LatLng(43.6884447292, 20.2201924985),
    const LatLng(48.2208812526, 29.62654341),
  );

  @override
  Widget build(BuildContext context) {
    final camConstraint = cnt >= 0
        ? CameraConstraint.contain(bounds: bounds)
        : const CameraConstraint.unconstrained();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FlutterMap(
        options: MapOptions(
          minZoom: 1,
          maxZoom: 20,
          initialZoom: 5.9,

          initialCenter: const LatLng(45.80565, 24.937853),
          cameraConstraint: camConstraint,
          //initialCameraFit: CameraFit.insideBounds(
          //  bounds: bounds,
          //),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: [
                  bounds.northWest,
                  bounds.northEast,
                  bounds.southEast,
                  bounds.southWest,
                ],
                color: Colors.red.withOpacity(0.5),
              ),
            ],
          ),
          const CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(45.80565, 24.937853),
                radius: 10,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
