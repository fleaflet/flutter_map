part of 'polygon_layer.dart';

void Function(Canvas canvas)? _buildLabelTextPainter({
  required math.Point<double> mapSize,
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
  if (rotationRad == 0) {
    if (dx + width / 2 < 0 || dx - width / 2 > mapSize.x) {
      return null;
    }
    if (dy + height / 2 < 0 || dy - height / 2 > mapSize.y) {
      return null;
    }
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

/// Use the Maxbox Polylabel algorithm to calculate the [LatLng] position for
/// a given list of points.
LatLng _computePolylabel(List<LatLng> points) {
  final labelPosition = polylabel(
    [
      List<math.Point>.generate(points.length,
          (i) => math.Point(points[i].longitude, points[i].latitude)),
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
