part of 'circle_layer.dart';

/// The [CustomPainter] used to draw [CircleMarker] for the [CircleLayer].
@immutable
class CirclePainter<R extends Object> extends CustomPainter {
  /// Reference to the list of [CircleMarker]s of the [CircleLayer].
  final List<CircleMarker<R>> circles;

  /// Reference to the [MapCamera].
  final MapCamera camera;

  /// See [PolylineLayer.hitNotifier]
  final LayerHitNotifier<R>? hitNotifier;

  /// Create a [CirclePainter] instance by providing the required
  /// reference objects.
  CirclePainter({
    required this.circles,
    required this.camera,
    required this.hitNotifier,
  });

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  static const _distance = Distance();

  @override
  bool? hitTest(Offset position) {
    _hits.clear();
    bool hasHit = false;

    final point = position.toPoint();
    final coordinate = camera.pointToLatLng(point);

    for (final circle in circles) {
      if (hasHit && circle.hitValue == null) continue;

      final center = camera.getOffsetFromOrigin(circle.point);
      final radius = circle.useRadiusInMeter
          ? (center -
                  camera.getOffsetFromOrigin(
                      _distance.offset(circle.point, circle.radius, 180)))
              .distance
          : circle.radius;

      final isInCircle =
          pow(point.x - center.dx, 2) + pow(point.y - center.dy, 2) <=
              radius * radius;

      if (isInCircle) {
        if (circle.hitValue != null) _hits.add(circle.hitValue!);
        hasHit = true;
      }
    }

    if (!hasHit) {
      hitNotifier?.value = null;
      return false;
    }

    hitNotifier?.value = LayerHitResult(
      hitValues: _hits,
      coordinate: coordinate,
      point: point,
    );
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    // Let's calculate all the points grouped by color and radius
    final points = <Color, Map<double, List<Offset>>>{};
    final pointsFilledBorder = <Color, Map<double, List<Offset>>>{};
    final pointsBorder = <Color, Map<double, Map<double, List<Offset>>>>{};
    for (final circle in circles) {
      final center = camera.getOffsetFromOrigin(circle.point);
      final radius = circle.useRadiusInMeter
          ? (center -
                  camera.getOffsetFromOrigin(
                      _distance.offset(circle.point, circle.radius, 180)))
              .distance
          : circle.radius;
      points[circle.color] ??= {};
      points[circle.color]![radius] ??= [];
      points[circle.color]![radius]!.add(center);

      if (circle.borderStrokeWidth > 0) {
        // Check if color have some transparency or not
        // As drawPoints is more efficient than drawCircle
        if (circle.color.alpha == 0xFF) {
          double radiusBorder = circle.radius + circle.borderStrokeWidth;
          if (circle.useRadiusInMeter) {
            final rBorder = _distance.offset(circle.point, radiusBorder, 180);
            final deltaBorder = center - camera.getOffsetFromOrigin(rBorder);
            radiusBorder = deltaBorder.distance;
          }
          pointsFilledBorder[circle.borderColor] ??= {};
          pointsFilledBorder[circle.borderColor]![radiusBorder] ??= [];
          pointsFilledBorder[circle.borderColor]![radiusBorder]!.add(center);
        } else {
          double realRadius = circle.radius;
          if (circle.useRadiusInMeter) {
            final rBorder = _distance.offset(circle.point, realRadius, 180);
            final deltaBorder = center - camera.getOffsetFromOrigin(rBorder);
            realRadius = deltaBorder.distance;
          }
          pointsBorder[circle.borderColor] ??= {};
          pointsBorder[circle.borderColor]![circle.borderStrokeWidth] ??= {};
          pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
              realRadius] ??= [];
          pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
                  realRadius]!
              .add(center);
        }
      }
    }

    // Now that all the points are grouped, let's draw them
    final paintBorder = Paint()..style = PaintingStyle.stroke;
    for (final color in pointsBorder.keys) {
      final paint = paintBorder..color = color;
      for (final borderWidth in pointsBorder[color]!.keys) {
        final pointsByRadius = pointsBorder[color]![borderWidth]!;
        final radiusPaint = paint..strokeWidth = borderWidth;
        for (final radius in pointsByRadius.keys) {
          final pointsByRadiusColor = pointsByRadius[radius]!;
          for (final offset in pointsByRadiusColor) {
            _paintCircle(canvas, offset, radius, radiusPaint);
          }
        }
      }
    }

    // Then the filled border in order to be under the circle
    final paintPoint = Paint()
      ..isAntiAlias = false
      ..strokeCap = StrokeCap.round;
    for (final color in pointsFilledBorder.keys) {
      final paint = paintPoint..color = color;
      final pointsByRadius = pointsFilledBorder[color]!;
      for (final radius in pointsByRadius.keys) {
        final pointsByRadiusColor = pointsByRadius[radius]!;
        final radiusPaint = paint..strokeWidth = radius * 2;
        _paintPoints(canvas, pointsByRadiusColor, radiusPaint);
      }
    }

    // And then the circle
    for (final color in points.keys) {
      final paint = paintPoint..color = color;
      final pointsByRadius = points[color]!;
      for (final radius in pointsByRadius.keys) {
        final pointsByRadiusColor = pointsByRadius[radius]!;
        final radiusPaint = paint..strokeWidth = radius * 2;
        _paintPoints(canvas, pointsByRadiusColor, radiusPaint);
      }
    }
  }

  void _paintPoints(Canvas canvas, List<Offset> offsets, Paint paint) {
    canvas.drawPoints(PointMode.points, offsets, paint);
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) =>
      circles != oldDelegate.circles || camera != oldDelegate.camera;
}
