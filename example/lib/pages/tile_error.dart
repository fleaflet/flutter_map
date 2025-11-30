import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

/// Example of tile loading systematically failing.
class ErrorTileBuilder extends StatelessWidget {
  static const String route = '/error_tile_builder';

  const ErrorTileBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Tile Builder')),
      drawer: const MenuDrawer(ErrorTileBuilder.route),
      body: FlutterMap(
        options: const MapOptions(
          initialZoom: 3,
        ),
        children: [
          TileLayer(
            // obviously wrong url template
            urlTemplate: 'https://example.com/{z}/{y}/{x}',
            tileBuilder: (context, tileWidget, tile) {
              if (tile.loadError) {
                return Center(
                  child: Text('${tile.coordinates.z}'
                      '/'
                      '${tile.coordinates.x}'
                      '/'
                      '${tile.coordinates.y}'),
                );
              }
              return tileWidget;
            },
          ),
        ],
      ),
    );
  }
}
