import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class PitchPage extends StatefulWidget {
  static const String route = 'pitch';

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
    final pitch = 60.0;
    return Scaffold(
      appBar: AppBar(title: Text('Pitch')),
      drawer: buildDrawer(context, PitchPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
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
              ],
            )),
          ],
        ),
      ),
    );
  }
}
