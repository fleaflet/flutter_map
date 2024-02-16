import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class ScaleBarPage extends StatelessWidget {
  static const String route = '/scalebar';

  const ScaleBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scale Bar Layer')),
      drawer: const MenuDrawer(ScaleBarPage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(51.5, -0.09),
          initialZoom: 5,
        ),
        children: [
          openStreetMapTileLayer,
          const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            padding: EdgeInsets.only(right: 10, left: 10, bottom: 40),
            alignment: Alignment.bottomLeft,
          ),
          const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            padding: EdgeInsets.only(right: 10, left: 10, bottom: 80),
            alignment: Alignment.bottomLeft,
            length: ScalebarLength.s,
          ),
          const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            alignment: Alignment.bottomCenter,
            length: ScalebarLength.s,
          ),
          const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            length: ScalebarLength.xxl,
          ),
          const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            padding: EdgeInsets.only(right: 10, left: 10, top: 40),
          ),
          const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            padding: EdgeInsets.only(right: 10, left: 10, top: 80),
            length: ScalebarLength.s,
          ),
        ],
      ),
    );
  }
}
