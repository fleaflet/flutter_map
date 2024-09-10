import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';

/// Display of a [TileImage] at given [TileCoordinates].
///
/// In most cases, the [positionCoordinates] are equal to tileImage coordinates.
/// Except when we display several worlds in the same map, or when we cross the
/// 180/-180 border.
class TileRenderer {
  /// TileImage to display.
  final TileImage tileImage;

  /// Position where to display [tileImage].
  final TileCoordinates positionCoordinates;

  /// Create an instance of [TileRenderer].
  const TileRenderer(this.tileImage, this.positionCoordinates);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TileRenderer &&
        other.positionCoordinates == positionCoordinates;
  }

  @override
  int get hashCode => positionCoordinates.hashCode;
}
