import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/map/options.dart';

class FlutterMapInternalState {
  final MapCamera mapCamera;
  final MapOptions options;

  const FlutterMapInternalState({
    required this.options,
    required this.mapCamera,
  });

  FlutterMapInternalState withMapCamera(MapCamera mapCamera) =>
      FlutterMapInternalState(
        options: options,
        mapCamera: mapCamera,
      );
}
