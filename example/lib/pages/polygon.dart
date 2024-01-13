import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/simplification_tolerance_slider.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';

class PolygonPage extends StatefulWidget {
  static const String route = '/polygon';

  const PolygonPage({super.key});

  @override
  State<PolygonPage> createState() => _PolygonPageState();
}

class _PolygonPageState extends State<PolygonPage> {
  static const double _initialSimplificationTolerance = 0.5;
  double simplificationTolerance = _initialSimplificationTolerance;

  final geoJsonParser = GeoJsonParser();
  late final Future<void> geoJsonLoader;

  @override
  void initState() {
    super.initState();
    geoJsonLoader = rootBundle
        .loadString('assets/138k-polygon-points.geojson.noformat')
        .then(geoJsonParser.parseGeoJsonAsString);
  }

  @override
  void dispose() {
    geoJsonLoader.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: const MenuDrawer(PolygonPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(58.87141, 47.81469),
              initialZoom: 10,
            ),
            children: [
              openStreetMapTileLayer,
              FutureBuilder(
                future: geoJsonLoader,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }

                  return PolygonLayer(
                    simplificationTolerance: simplificationTolerance,
                    polygons: geoJsonParser.polygons,
                  );
                },
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: SimplificationToleranceSlider(
              initialTolerance: _initialSimplificationTolerance,
              onChangedTolerance: (v) =>
                  setState(() => simplificationTolerance = v),
            ),
          ),
        ],
      ),
    );
  }
}
