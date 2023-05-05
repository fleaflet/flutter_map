import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';

class TileRangeCalculator {
  final double tileSize;

  const TileRangeCalculator({required this.tileSize});

  /// Calculates the visible pixel bounds at the [tileZoom] zoom level when
  /// viewing the map from the [viewingZoom] centered at the [center]. The
  /// resulting tile range is expanded by [panBuffer].
  DiscreteTileRange calculate({
    // The map state used to calculate the bounds.
    required FlutterMapState mapState,
    // The zoom level at which the bounds should be calculated.
    required int tileZoom,
    // The center from which the map is viewed, defaults to [mapState.center].
    LatLng? center,
    // The zoom from which the map is viewed, defaults to [mapState.zoom].
    double? viewingZoom,
  }) {
    return DiscreteTileRange.fromPixelBounds(
      zoom: tileZoom,
      tileSize: tileSize,
      pixelBounds: _calculatePixelBounds(
        mapState,
        center ?? mapState.center,
        viewingZoom ?? mapState.zoom,
        tileZoom,
      ),
    );
  }

  Bounds<double> _calculatePixelBounds(
    FlutterMapState mapState,
    LatLng center,
    double viewingZoom,
    int tileZoom,
  ) {
    final tileZoomDouble = tileZoom.toDouble();
    final scale = mapState.getZoomScale(viewingZoom, tileZoomDouble);
    final pixelCenter =
        mapState.project(center, tileZoomDouble).floor().toDoublePoint();
    final halfSize = mapState.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }
}
