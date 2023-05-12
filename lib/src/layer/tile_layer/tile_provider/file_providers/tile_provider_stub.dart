import 'package:flutter/rendering.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';

/// [TileProvider] to fetch tiles from the local filesystem (not asset store)
///
/// Stub for IO & web specific implementations.
///
/// This web platform does not support reading from the local filesystem, and
/// therefore throws an [UnsupportedError] when [getImage] is invoked.
class FileTileProvider extends TileProvider {
  /// [TileProvider] to fetch tiles from the local filesystem (not asset store)
  ///
  /// Stub for IO & web specific implementations.
  ///
  /// This web platform does not support reading from the local filesystem, and
  /// therefore throws an [UnsupportedError] when [getImage] is invoked.
  FileTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      throw UnsupportedError(
          'The current platform does not have access to IO (the local filesystem), and therefore does not support `FileTileProvider`');
}
