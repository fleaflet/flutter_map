import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_renderer.dart';

/// A key that identifies rendering of a [TileImage] at given [TileCoordinates].
///
/// Two [TileKey]s are equal when they reference the same [TileImage]
/// instance and have equal [positionCoordinates].
final class TileKey extends LocalKey {
  /// Tile image to identify by instance.
  final TileImage tileImage;

  /// Position where [tileImage] is rendered.
  final TileCoordinates positionCoordinates;

  /// Creates a [TileKey] for the given [TileRenderer].
  ///
  /// The [tileImage] is compared by identity, while [positionCoordinates] are
  /// compared by value.
  TileKey(TileRenderer renderer)
      : tileImage = renderer.tileImage,
        positionCoordinates = renderer.positionCoordinates;

  @override
  bool operator ==(Object other) {
    return other is TileKey &&
        identical(other.tileImage, tileImage) &&
        other.positionCoordinates == positionCoordinates;
  }

  @override
  int get hashCode => Object.hash(
        identityHashCode(tileImage),
        positionCoordinates,
      );
}
