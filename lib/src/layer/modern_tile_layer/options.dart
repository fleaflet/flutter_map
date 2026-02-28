import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_layer.dart';
import 'package:meta/meta.dart';

/// Configuration of a [BaseTileLayer], which can be used by all parts of the
/// tile layer.
@immutable
class TileLayerOptions {
  final Crs? crs;

  final double maxZoom; // TODO: Is this the same as the old `nativeMaxZoom`?
  final double zoomOffset;
  final bool zoomReverse;

  /// Size in pixels of each tile image.
  ///
  /// Should be a positive power of 2. Defaults to 256px.
  ///
  /// If increasing past 256(px) (default), adjust [zoomOffset] as necessary,
  /// for example 512px: -1.
  final int tileDimension;

  /// Configuration of a [BaseTileLayer], which can be used by all parts of the
  /// tile layer.
  const TileLayerOptions({
    this.crs,
    this.maxZoom = double.infinity,
    this.zoomOffset = 0,
    this.zoomReverse = false,
    this.tileDimension = 256,
  });

  @override
  int get hashCode =>
      Object.hash(crs, maxZoom, zoomOffset, zoomReverse, tileDimension);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileLayerOptions &&
          other.crs == crs &&
          other.maxZoom == maxZoom &&
          other.zoomOffset == zoomOffset &&
          other.zoomReverse == zoomReverse &&
          other.tileDimension == tileDimension);
}
