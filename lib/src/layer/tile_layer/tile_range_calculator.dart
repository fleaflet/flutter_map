import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

class TileRangeCalculator {
  final double tileSize;

  const TileRangeCalculator({required this.tileSize});

  /// Calculates the visible pixel bounds at the [tileZoom] zoom level when
  /// viewing the map from the [viewingZoom] centered at the [center]. The
  /// resulting tile range is expanded by [panBuffer].
  DiscreteTileRange calculate({
    // The map camera used to calculate the bounds.
    required MapCamera mapCamera,
    // The zoom level at which the bounds should be calculated.
    required int tileZoom,
    // The center from which the map is viewed, defaults to [mapCamera.center].
    LatLng? center,
    // The zoom from which the map is viewed, defaults to [mapCamera.zoom].
    double? viewingZoom,
  }) {
    return DiscreteTileRange.fromPixelBounds(
      zoom: tileZoom,
      tileSize: tileSize,
      pixelBounds: _calculatePixelBounds(
        mapCamera,
        center ?? mapCamera.center,
        viewingZoom ?? mapCamera.zoom,
        tileZoom,
      ),
    );
  }

  Bounds<double> _calculatePixelBounds(
    MapCamera mapCamera,
    LatLng center,
    double viewingZoom,
    int tileZoom,
  ) {
    final tileZoomDouble = tileZoom.toDouble();
    final scale = mapCamera.getZoomScale(viewingZoom, tileZoomDouble);
    final pixelCenter =
        mapCamera.project(center, tileZoomDouble).floor().toDoublePoint();
    final halfSize = mapCamera.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }
}
