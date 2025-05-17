import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Fetch tiles from the local filesystem (not asset store), where the tile URL
/// is a path within the filesystem.
///
/// Uses [FileImage] internally.
///
/// If [TileLayer.fallbackUrl] is specified, the [File] must first be
/// synchronously checked for existence - this blocks the main thread, and as
/// such, specifying [TileLayer.fallbackUrl] should be avoided when using this
/// provider.
class FileTileProvider extends TileProvider {
  /// Fetch tiles from the local filesystem (not asset store), where the tile URL
  /// is a path within the filesystem.
  ///
  /// Uses [FileImage] internally.
  ///
  /// If [TileLayer.fallbackUrl] is specified, the [File] must first be
  /// synchronously checked for existence - this blocks the main thread, and as
  /// such, specifying [TileLayer.fallbackUrl] should be avoided when using this
  /// provider.
  FileTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = File(getTileUrl(coordinates, options));
    final fallbackUrl = getTileFallbackUrl(coordinates, options);

    if (fallbackUrl == null || file.existsSync()) return FileImage(file);
    return FileImage(File(fallbackUrl));
  }
}
