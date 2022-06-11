import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class TileLoadingErrorHandle extends StatefulWidget {
  static const String route = '/tile_loading_error_handle';

  const TileLoadingErrorHandle({Key? key}) : super(key: key);

  @override
  _TileLoadingErrorHandleState createState() => _TileLoadingErrorHandleState();
}

class _TileLoadingErrorHandleState extends State<TileLoadingErrorHandle> {
  @override
  Widget build(BuildContext context) {
    var needLoadingError = true;

    return Scaffold(
      appBar: AppBar(title: const Text('Tile Loading Error Handle')),
      drawer: buildDrawer(context, TileLoadingErrorHandle.route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('Turn on Airplane mode and try to move or zoom map'),
            ),
            Flexible(
              child: Builder(builder: (BuildContext context) {
                return FlutterMap(
                  options: MapOptions(
                    center: LatLng(51.5, -0.09),
                    zoom: 5.0,
                    onPositionChanged: (MapPosition mapPosition, bool _) {
                      needLoadingError = true;
                    },
                  ),
                  layers: [
                    TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      // For example purposes. It is recommended to use
                      // TileProvider with a caching and retry strategy, like
                      // NetworkTileProvider or CachedNetworkTileProvider
                      tileProvider: const NonCachingNetworkTileProvider(),
                      errorTileCallback: (Tile tile, error) {
                        if (needLoadingError) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(seconds: 1),
                              content: Text(
                                error.toString(),
                                style: const TextStyle(color: Colors.black),
                              ),
                              backgroundColor: Colors.deepOrange,
                            ));
                          });
                          needLoadingError = false;
                        }
                      },
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
