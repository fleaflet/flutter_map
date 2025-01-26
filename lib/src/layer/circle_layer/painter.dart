part of 'circle_layer.dart';

/// The [CustomPainter] used to draw [CircleMarker] for the [CircleLayer].
base class CirclePainter<R extends Object>
    extends HitDetectablePainter<R, CircleMarker<R>> {
  /// Reference to the list of [CircleMarker]s of the [CircleLayer].
  final List<CircleMarker<R>> circles;

  /// Create a [CirclePainter] instance by providing the required
  /// reference objects.
  CirclePainter({
    required this.circles,
    required super.camera,
    required super.hitNotifier,
  });

  static const _distance = Distance();

  @override
  bool elementHitTest(
    CircleMarker<R> element, {
    required Offset point,
    required LatLng coordinate,
  }) {
    final worldWidth = _getWorldWidth();

    /// Returns null if invisible, true if hit, false if not hit.
    bool? checkIfHit(double worldWidth) {
      final center = _getOffset(element, worldWidth);
      final radius = _getRadius(center, element);
      if (!_isVisible(
        screenRect: _screenRect,
        center: center,
        radius: radius,
      )) {
        return null;
      }

      return pow(point.dx - center.dx, 2) + pow(point.dy - center.dy, 2) <=
          radius * radius;
    }

    if (checkIfHit(0) ?? false) {
      return true;
    }

    // Repeat over all worlds (<--||-->) until culling determines that
    // that element is out of view, and therefore all further elements in
    // that direction will also be
    if (worldWidth == 0) return false;
    for (double shift = -worldWidth;; shift -= worldWidth) {
      final isHit = checkIfHit(shift);
      if (isHit == null) break;
      if (isHit) return true;
    }
    for (double shift = worldWidth;; shift += worldWidth) {
      final isHit = checkIfHit(shift);
      if (isHit == null) break;
      if (isHit) return true;
    }

    return false;
  }

  @override
  Iterable<CircleMarker<R>> get elements => circles;

  late Rect _screenRect;

  @override
  void paint(Canvas canvas, Size size) {
    _screenRect = Offset.zero & size;
    canvas.clipRect(_screenRect);

    final worldWidth = _getWorldWidth();

    // Let's calculate all the points grouped by color and radius
    final points = <Color, Map<double, List<Offset>>>{};
    final pointsFilledBorder = <Color, Map<double, List<Offset>>>{};
    final pointsBorder = <Color, Map<double, Map<double, List<Offset>>>>{};
    for (final circle in circles) {
      bool checkIfVisible(double worldWidth) {
        bool result = false;
        final center = _getOffset(circle, worldWidth);

        bool isVisible(double radius) {
          if (_isVisible(
            screenRect: _screenRect,
            center: center,
            radius: radius,
          )) {
            return result = true;
          }
          return false;
        }

        final radius = _getRadius(center, circle);
        if (isVisible(radius)) {
          points[circle.color] ??= {};
          points[circle.color]![radius] ??= [];
          points[circle.color]![radius]!.add(center);
        }

        if (circle.borderStrokeWidth > 0) {
          // Check if color have some transparency or not
          // As drawPoints is more efficient than drawCircle
          if (circle.color.a == 1) {
            double radiusBorder = circle.radius + circle.borderStrokeWidth;
            if (circle.useRadiusInMeter) {
              final rBorder = _distance.offset(circle.point, radiusBorder, 180);
              final deltaBorder = center - camera.getOffsetFromOrigin(rBorder);
              radiusBorder = deltaBorder.distance;
            }
            if (isVisible(radiusBorder)) {
              pointsFilledBorder[circle.borderColor] ??= {};
              pointsFilledBorder[circle.borderColor]![radiusBorder] ??= [];
              pointsFilledBorder[circle.borderColor]![radiusBorder]!
                  .add(center);
            }
          } else {
            double realRadius = circle.radius;
            if (circle.useRadiusInMeter) {
              final rBorder = _distance.offset(circle.point, realRadius, 180);
              final deltaBorder = center - camera.getOffsetFromOrigin(rBorder);
              realRadius = deltaBorder.distance;
            }
            if (isVisible(circle.borderStrokeWidth)) {
              pointsBorder[circle.borderColor] ??= {};
              pointsBorder[circle.borderColor]![circle.borderStrokeWidth] ??=
                  {};
              pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
                  realRadius] ??= [];
              pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
                      realRadius]!
                  .add(center);
            }
          }
        }
        return result;
      }

      checkIfVisible(0);

      // Repeat over all worlds (<--||-->) until culling determines that
      // that element is out of view, and therefore all further elements in
      // that direction will also be
      if (worldWidth == 0) continue;
      for (double shift = -worldWidth;; shift -= worldWidth) {
        final isVisible = checkIfVisible(shift);
        if (!isVisible) break;
      }
      for (double shift = worldWidth;; shift += worldWidth) {
        final isVisible = checkIfVisible(shift);
        if (!isVisible) break;
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

  Offset _getOffset(CircleMarker circle, double worldWidth) =>
      camera.getOffsetFromOrigin(circle.point).translate(
            worldWidth,
            0,
          );

  /// Returns true if a centered circle with this radius is on the screen.
  bool _isVisible({
    required Rect screenRect,
    required Offset center,
    required double radius,
  }) =>
      screenRect.overlaps(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

  double _getRadius(Offset center, CircleMarker<R> circle) =>
      circle.useRadiusInMeter
          ? (center -
                  camera.getOffsetFromOrigin(
                      _distance.offset(circle.point, circle.radius, 180)))
              .distance
          : circle.radius;

  double _getWorldWidth() => camera.getWorldWidthAtZoom();
}
