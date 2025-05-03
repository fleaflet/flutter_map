import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';

/// Fetch tiles from the local filesystem (not asset store), where the tile URL
/// is a path within the filesystem.
///
/// Stub for IO specific implementations.
///
/// This web platform does not support reading from the local filesystem, and
/// therefore throws an [UnsupportedError] when [getImage] is invoked.
class FileTileProvider extends TileProvider {
  /// Fetch tiles from the local filesystem (not asset store), where the tile URL
  /// is a path within the filesystem.
  ///
  /// Stub for IO specific implementations.
  ///
  /// This web platform does not support reading from the local filesystem, and
  /// therefore throws an [UnsupportedError] when [getImage] is invoked.
  FileTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      throw UnsupportedError(
          'The current platform does not have access to IO (the local filesystem), and therefore does not support `FileTileProvider`');
}
