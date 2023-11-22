import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

class TileLoadingErrorHandle extends StatefulWidget {
  static const String route = '/tile_loading_error_handle';

  const TileLoadingErrorHandle({Key? key}) : super(key: key);

  @override
  _TileLoadingErrorHandleState createState() => _TileLoadingErrorHandleState();
}

class _TileLoadingErrorHandleState extends State<TileLoadingErrorHandle> {
  static const _showSnackBarDuration = Duration(seconds: 1);
  bool _simulateTileLoadErrors = false;
  DateTime? _lastShowedTileLoadError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tile Loading Error Handle')),
      drawer: const MenuDrawer(TileLoadingErrorHandle.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Simulate tile loading errors'),
              value: _simulateTileLoadErrors,
              onChanged: (newValue) => setState(() {
                _simulateTileLoadErrors = newValue;
              }),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                  'Enable tile load error simulation or disable internet and try to move or zoom map.'),
            ),
            Flexible(
              child: Builder(builder: (BuildContext context) {
                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(51.5, -0.09),
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                      evictErrorTileStrategy: EvictErrorTileStrategy.none,
                      errorTileCallback: (tile, error, stackTrace) {
                        if (_showErrorSnackBar) {
                          _lastShowedTileLoadError = DateTime.now();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: _showSnackBarDuration,
                              content: Text(
                                error.toString(),
                                style: const TextStyle(color: Colors.black),
                              ),
                              backgroundColor: Colors.deepOrange,
                            ));
                          });
                        }
                      },
                      tileProvider: _simulateTileLoadErrors
                          ? _SimulateErrorsTileProvider()
                          : null,
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

  bool get _showErrorSnackBar =>
      _lastShowedTileLoadError == null ||
      DateTime.now().difference(_lastShowedTileLoadError!) -
              const Duration(milliseconds: 50) >
          _showSnackBarDuration;
}

class _SimulateErrorsTileProvider extends TileProvider {
  _SimulateErrorsTileProvider() : super();

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) =>
      _SimulateErrorImageProvider();
}

class _SimulateErrorImageProvider
    extends ImageProvider<_SimulateErrorImageProvider> {
  _SimulateErrorImageProvider();

  @override
  ImageStreamCompleter loadImage(
    _SimulateErrorImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      _SimulateErrorImageStreamCompleter();

  @override
  Future<_SimulateErrorImageProvider> obtainKey(ImageConfiguration _) =>
      Future.error('Simulated tile loading error');
}

class _SimulateErrorImageStreamCompleter extends ImageStreamCompleter {
  _SimulateErrorImageStreamCompleter() {
    throw 'Simulated tile loading error';
  }
}
