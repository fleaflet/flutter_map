import 'package:flutter_map/plugin_api.dart';

class FlutterMapInternalState {
  final FlutterMapState mapState;
  final MapOptions options;

  const FlutterMapInternalState({
    required this.options,
    required this.mapState,
  });

  FlutterMapInternalState withMapState(FlutterMapState mapState) =>
      FlutterMapInternalState(
        options: options,
        mapState: mapState,
      );
}
