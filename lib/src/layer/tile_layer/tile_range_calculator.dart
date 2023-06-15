import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/map/flutter_map_frame.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

class TileRangeCalculator {
  final double tileSize;

  const TileRangeCalculator({required this.tileSize});

  /// Calculates the visible pixel bounds at the [tileZoom] zoom level when
  /// viewing the map from the [viewingZoom] centered at the [center]. The
  /// resulting tile range is expanded by [panBuffer].
  DiscreteTileRange calculate({
    // The map frame used to calculate the bounds.
    required MapFrame mapFrame,
    // The zoom level at which the bounds should be calculated.
    required int tileZoom,
    // The center from which the map is viewed, defaults to [mapFrame.center].
    LatLng? center,
    // The zoom from which the map is viewed, defaults to [mapFrame.zoom].
    double? viewingZoom,
  }) {
    return DiscreteTileRange.fromPixelBounds(
      zoom: tileZoom,
      tileSize: tileSize,
      pixelBounds: _calculatePixelBounds(
        mapFrame,
        center ?? mapFrame.center,
        viewingZoom ?? mapFrame.zoom,
        tileZoom,
      ),
    );
  }

  Bounds<double> _calculatePixelBounds(
    MapFrame mapFrame,
    LatLng center,
    double viewingZoom,
    int tileZoom,
  ) {
    final tileZoomDouble = tileZoom.toDouble();
    final scale = mapFrame.getZoomScale(viewingZoom, tileZoomDouble);
    final pixelCenter =
        mapFrame.project(center, tileZoomDouble).floor().toDoublePoint();
    final halfSize = mapFrame.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }
}
