import 'package:flutter_map/plugin_api.dart';

class FlutterMapInternalState {
  final FlutterMapFrame mapFrame;
  final MapOptions options;

  const FlutterMapInternalState({
    required this.options,
    required this.mapFrame,
  });

  FlutterMapInternalState withMapFrame(FlutterMapFrame mapFrame) =>
      FlutterMapInternalState(
        options: options,
        mapFrame: mapFrame,
      );
}
