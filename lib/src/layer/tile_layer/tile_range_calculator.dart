import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// The [TileRangeCalculator] helps to calculate the bounds in pixel.
@immutable
class TileRangeCalculator {
  /// The tile size in pixels.
  final double tileSize;

  /// Create a new [TileRangeCalculator] instance.
  const TileRangeCalculator({required this.tileSize});

  /// Calculates the visible pixel bounds at the [tileZoom] zoom level when
  /// viewing the map from the [viewingZoom] centered at the [center]. The
  /// resulting tile range is expanded by panBuffer.
  DiscreteTileRange calculate({
    // The map camera used to calculate the bounds.
    required MapCamera camera,
    // The zoom level at which the bounds should be calculated.
    required int tileZoom,
    // The center from which the map is viewed, defaults to [camera.center].
    LatLng? center,
    // The zoom from which the map is viewed, defaults to [camera.zoom].
    double? viewingZoom,
  }) {
    return DiscreteTileRange.fromPixelBounds(
      zoom: tileZoom,
      tileSize: tileSize,
      pixelBounds: _calculatePixelBounds(
        camera,
        center ?? camera.center,
        viewingZoom ?? camera.zoom,
        tileZoom,
      ),
    );
  }

  Bounds<double> _calculatePixelBounds(
    MapCamera camera,
    LatLng center,
    double viewingZoom,
    int tileZoom,
  ) {
    final tileZoomDouble = tileZoom.toDouble();
    final scale = camera.getZoomScale(viewingZoom, tileZoomDouble);
    final pixelCenter =
        camera.project(center, tileZoomDouble).floor().toDoublePoint();
    final halfSize = camera.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }
}
