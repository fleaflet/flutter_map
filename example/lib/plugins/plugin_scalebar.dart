import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/pages/scale_layer_plugin_option.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class PluginScaleBar extends StatelessWidget {
  static const String route = '/plugin_scalebar';

  const PluginScaleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scale Bar Plugin')),
      drawer: const MenuDrawer(PluginScaleBar.route),
      body: Flexible(
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(51.5, -0.09),
            initialZoom: 5,
          ),
          children: [
            openStreetMapTileLayer,
            ScaleLayerWidget(
              options: ScaleLayerPluginOption(
                lineColor: Colors.black,
                lineWidth: 3,
                textStyle: const TextStyle(color: Colors.black, fontSize: 14),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
