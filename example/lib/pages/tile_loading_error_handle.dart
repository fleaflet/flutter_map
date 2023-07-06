import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

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
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('Turn on Airplane mode and try to move or zoom map'),
            ),
            Flexible(
              child: Builder(builder: (BuildContext context) {
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(51.5, -0.09),
                    initialZoom: 5,
                    onPositionChanged: (MapPosition mapPosition, bool _) {
                      needLoadingError = true;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                      // For example purposes. It is recommended to use
                      // TileProvider with a caching and retry strategy, like
                      // NetworkTileProvider or CachedNetworkTileProvider
                      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                      errorTileCallback: (tile, error, stackTrace) {
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
