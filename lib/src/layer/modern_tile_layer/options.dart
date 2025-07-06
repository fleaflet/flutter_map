import 'package:meta/meta.dart';

@immutable
class TileLayerOptions {
  final double maxZoom;
  final double zoomOffset;
  final bool zoomReverse;

  final int tileDimension;

  const TileLayerOptions({
    this.maxZoom = double.infinity,
    this.zoomOffset = 0,
    this.zoomReverse = false,
    this.tileDimension = 256,
  });

  @override
  int get hashCode =>
      Object.hash(maxZoom, zoomOffset, zoomReverse, tileDimension);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileLayerOptions &&
          other.maxZoom == maxZoom &&
          other.zoomOffset == zoomOffset &&
          other.zoomReverse == zoomReverse &&
          other.tileDimension == tileDimension);
}
