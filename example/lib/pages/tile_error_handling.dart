import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class TileErrorHandling extends StatefulWidget {
  static const String route = '/tile_error_handling';

  const TileErrorHandling({Key? key}) : super(key: key);

  @override
  _TileErrorHandlingState createState() => _TileErrorHandlingState();
}

class _TileErrorHandlingState extends State<TileErrorHandling> {
  static const _showSnackBarDuration = Duration(seconds: 1);
  static final _placeholderImage = TilePlaceholderImage.generate();

  late final TileLayerController _tileLayerController;

  bool _simulateTileLoadErrors = false;
  DateTime? _lastShowedTileLoadError;

  @override
  void initState() {
    super.initState();
    _tileLayerController = TileLayerController();
  }

  @override
  void dispose() {
    _tileLayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tile Error Handling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('Tile Error Handling'),
                  content: Text(
                    'To trigger tile loading errors enable tile loading error '
                    'simulation or disable internet access and try to move the '
                    'map.',
                  ),
                ),
              );
            },
          )
        ],
      ),
      drawer: buildDrawer(context, TileErrorHandling.route),
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
            ElevatedButton(
              onPressed: () => _tileLayerController.reloadErrorTiles(),
              child: const Text('Reload error tiles'),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Builder(builder: (BuildContext context) {
                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(51.5, -0.09),
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      controller: _tileLayerController,
                      placeholderImage: _placeholderImage,
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
  ImageStreamCompleter load(
    _SimulateErrorImageProvider key,
    Future<ui.Codec> Function(
      Uint8List, {
      bool allowUpscaling,
      int? cacheHeight,
      int? cacheWidth,
    }) decode,
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
