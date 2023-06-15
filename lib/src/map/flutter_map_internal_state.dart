import 'package:flutter_map/plugin_api.dart';

class FlutterMapInternalState {
  final MapFrame mapFrame;
  final MapOptions options;

  const FlutterMapInternalState({
    required this.options,
    required this.mapFrame,
  });

  FlutterMapInternalState withMapFrame(MapFrame mapFrame) =>
      FlutterMapInternalState(
        options: options,
        mapFrame: mapFrame,
      );
}
