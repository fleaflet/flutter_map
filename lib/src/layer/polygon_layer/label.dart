part of 'polygon_layer.dart';

void Function(Canvas canvas)? _buildLabelTextPainter({
  required Size mapSize,
  required Offset placementPoint,
  required ({Offset min, Offset max}) bounds,
  required TextPainter textPainter,
  required double rotationRad,
  required bool rotate,
  required double padding,
}) {
  final dx = placementPoint.dx;
  final dy = placementPoint.dy;
  final width = textPainter.width;
  final height = textPainter.height;

  // Cull labels where the polygon is still on the map but the label would not be.
  // Currently this is only enabled when the map isn't rotated, since the placementOffset
  // is relative to the MobileLayerTransformer rather than in actual screen coordinates.
  final double textWidth;
  final double textHeight;
  final double mapWidth;
  final double mapHeight;
  if (rotationRad == 0) {
    textWidth = width;
    textHeight = height;
    mapWidth = mapSize.width;
    mapHeight = mapSize.height;
  } else {
    // lazily we imagine the worst case scenario regarding sizes, instead of
    // computing the angles
    textWidth = textHeight = max(width, height);
    mapWidth = mapHeight = max(mapSize.width, mapSize.height);
  }
  if (dx + textWidth / 2 < 0 || dx - textWidth / 2 > mapWidth) {
    return null;
  }
  if (dy + textHeight / 2 < 0 || dy - textHeight / 2 > mapHeight) {
    return null;
  }

  // Note: I'm pretty sure this doesn't work for concave shapes. It would be more
  // correct to evaluate the width of the polygon at the height of the label.
  if (bounds.max.dx - bounds.min.dx - padding > width) {
    return (canvas) {
      if (rotate) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(-rotationRad);
        canvas.translate(-dx, -dy);
      }

      textPainter.paint(
        canvas,
        Offset(
          dx - width / 2,
          dy - height / 2,
        ),
      );

      if (rotate) {
        canvas.restore();
      }
    };
  }
  return null;
}

/// Calculate the [LatLng] position for the given [PolygonLabelPlacement].
LatLng _computeLabelPosition(
  PolygonLabelPlacement labelPlacement,
  List<LatLng> points,
) {
  return switch (labelPlacement) {
    PolygonLabelPlacement.centroid => _computeCentroid(points),
    PolygonLabelPlacement.centroidWithMultiWorld =>
      _computeCentroidWithMultiWorld(points),
    PolygonLabelPlacement.polylabel => _computePolylabel(points),
  };
}

/// Calculate the centroid of a given list of [LatLng] points.
LatLng _computeCentroid(List<LatLng> points) {
  return LatLng(
    points.map((e) => e.latitude).average,
    points.map((e) => e.longitude).average,
  );
}

/// Calculate the centroid of a given list of [LatLng] points with multiple worlds.
LatLng _computeCentroidWithMultiWorld(List<LatLng> points) {
  if (points.isEmpty) return _computeCentroid(points);
  const halfWorld = 180;
  int count = 0;
  double sum = 0;
  late double lastLng;
  for (final LatLng point in points) {
    double lng = point.longitude;
    count++;
    if (count > 1) {
      if (lng - lastLng > halfWorld) {
        lng -= 2 * halfWorld;
      } else if (lng - lastLng < -halfWorld) {
        lng += 2 * halfWorld;
      }
    }
    lastLng = lng;
    sum += lastLng;
  }
  return LatLng(points.map((e) => e.latitude).average, sum / count);
}

/// Use the Maxbox Polylabel algorithm to calculate the [LatLng] position for
/// a given list of points.
LatLng _computePolylabel(List<LatLng> points) {
  final labelPosition = polylabel(
    [
      List<Point<double>>.generate(points.length,
          (i) => Point<double>(points[i].longitude, points[i].latitude)),
    ],
    // "precision" is a bit of a misnomer. It's a threshold for when to stop
    // dividing-and-conquering the polygon in the hopes of finding a better
    // point with more distance to the polygon's outline. It's given in
    // point-units, i.e. degrees here. A bigger number means less precision,
    // i.e. cheaper at the expense off less optimal label placement.
    // TODO: Make this an external option
    precision: 0.0001,
  );
  return LatLng(
    labelPosition.point.y.toDouble(),
    labelPosition.point.x.toDouble(),
  );
}

/// Defines the algorithm used to calculate the position of the [Polygon] label.
///
/// > [!IMPORTANT]
/// > If your project allows users to browse across multiple worlds, and your
/// > polygons may be over the anti-meridan boundary, [centroidWithMultiWorld]
/// > must be used - other algorithms will produce unexpected results.
enum PolygonLabelPlacement {
  /// Use the centroid of the [Polygon] outline as position for the label.
  centroid,

  /// Use the centroid in a multi-world as position for the label.
  centroidWithMultiWorld,

  /// Use the Mapbox Polylabel algorithm as position for the label.
  polylabel,
}
