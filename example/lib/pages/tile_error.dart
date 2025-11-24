import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

/// Example of tile loading systematically failing.
class TileErrorPage extends StatelessWidget {
  static const String route = '/tile_error';

  const TileErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tile Error')),
      drawer: const MenuDrawer(TileErrorPage.route),
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
