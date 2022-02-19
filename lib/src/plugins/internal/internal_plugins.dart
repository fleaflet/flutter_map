import 'package:flutter_map/flutter_map.dart';

class InternalPlugins {
  static List<MapPlugin> internalPlugins = [
    CircleLayerPlugin(),
    GroupLayerPlugin(),
    MarkerLayerPlugin(),
    OverlayImageLayerPlugin(),
    PolygonLayerPlugin(),
    PolylineLayerPlugin(),
    TileLayerPlugin(),
  ];
}
