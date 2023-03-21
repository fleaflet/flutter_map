import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_transformation.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';

class TransformationCalculator {
  final Map<double, CustomPoint> _zoomToPixelOrigin = {};

  CustomPoint getOrCalculateOriginAt(double zoom, FlutterMapState map) {
    final level = _zoomToPixelOrigin[zoom];
    if (level != null) return level;

    final result = _zoomToPixelOrigin[zoom] = map.project(
      map.unproject(map.pixelOrigin),
      zoom,
    );
    return result;
  }

  List<double> whereLevel(bool Function(double level) test) {
    final result = <double>[];
    for (final levelZoom in _zoomToPixelOrigin.keys) {
      if (test(levelZoom)) result.add(levelZoom);
    }

    return result;
  }

  void removeLevel(double levelZoom) {
    _zoomToPixelOrigin.remove(levelZoom);
  }

  TileTransformation transformationFor(double zoom, FlutterMapState map) {
    final origin = _zoomToPixelOrigin[zoom]!;
    final scale = map.getZoomScale(map.zoom, zoom);
    final pixelOrigin = map.getNewPixelOrigin(map.center, map.zoom).round();
    final translate = origin.multiplyBy(scale) - pixelOrigin;
    return TileTransformation(scale: scale, translate: translate);
  }
}
