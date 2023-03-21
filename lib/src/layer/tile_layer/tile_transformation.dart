import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

@immutable
class TileTransformation {
  final CustomPoint scaledTileSize;
  final Matrix3 transformation;

  const TileTransformation({
    required this.scaledTileSize,
    required this.transformation,
  });

  factory TileTransformation.calculate({
    required FlutterMapState map,
    required double tileZoom,
    required CustomPoint tileSize,
  }) {
    final translate = map.project(
      map.unproject(map.pixelOrigin),
      tileZoom,
    );
    final scale = map.getZoomScale(map.zoom, tileZoom);

    return TileTransformation(
      scaledTileSize: tileSize * scale,
      transformation: Matrix3(
        1, 0, 0, //
        0, 1, 0, //
        -translate.x as double, -translate.y as double, 1, //
      )..scale(scale),
    );
  }
}
