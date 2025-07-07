import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/raster_tile_fetcher.dart';
import 'package:meta/meta.dart';

/// Raster tile data associated with a particular tile coordinate
///
/// This is used for communication between the [RasterTileFetcher] and the
/// raster tile renderer.
///
/// It is not usually necessary to consume this externally.
class RasterTileData implements TileData {
  /// Actual raster image resource
  final ImageProvider image;

  /// Raster tile data associated with a particular tile coordinate
  const RasterTileData({required this.image, required void Function() dispose})
      : _dispose = dispose;

  @override
  bool get isLoaded => throw UnimplementedError();

  @override
  Future<void> get whenLoaded => throw UnimplementedError();

  @internal
  @override
  void dispose() {
    _dispose();
  }

  final void Function() _dispose;
}
