import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class PitchPage extends StatefulWidget {
  static const String route = 'pitch';

  const PitchPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PitchPage();
  }
}

class _PitchPage extends State<PitchPage> {
  late MapController controller;

  @override
  void initState() {
    super.initState();
    controller = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = LatLng(49.246292, -123.116226);
    const pitch = 60.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Pitch')),
      drawer: buildDrawer(context, PitchPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'Showing (${coordinates.latitude}, ${coordinates.longitude}) at pitch $pitch'),
            ),
            Flexible(
                child: FlutterMap(
              options:
                  MapOptions(center: coordinates, zoom: 10.0, pitch: pitch),
              mapController: controller,
              layers: [
                TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c']),
                MarkerLayerOptions(key: const Key("pitchMarkers"), markers: [
                  _marker(coordinates, Colors.grey.shade600, rotate: false)
                ]),
                MarkerLayerOptions(
                    key: const Key("otherMarkers"),
                    applyPitch: false,
                    markers: [_marker(coordinates, Colors.red, rotate: false)]),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Marker _marker(LatLng coordinates, Color color, {required bool rotate}) =>
      Marker(
        width: 48.0,
        height: 48.0,
        point: coordinates,
        builder: (ctx) => Icon(Icons.location_pin, color: color, size: 48),
        rotate: rotate,
        anchorPos: AnchorPos.align(AnchorAlign.top),
      );
}
