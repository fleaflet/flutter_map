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
    final radius =
        _getRadiusInPixel(element, element.radius + element.borderStrokeWidth);
    final initialCenter = _getOffset(element.point);

    /// Returns null if invisible, true if hit, false if not hit.
    bool? checkIfHit(double shift) {
      final center = initialCenter + Offset(shift, 0);
      if (!_isVisible(
        screenRect: _screenRect,
        center: center,
        radiusInPixel: radius,
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
      final radiusWithoutBorder = _getRadiusInPixel(circle, circle.radius);
      final radiusWithBorder =
          _getRadiusInPixel(circle, circle.radius + circle.borderStrokeWidth);
      final initialCenter = _getOffset(circle.point);

      bool checkIfVisible(double shift) {
        bool result = false;
        final center = initialCenter + Offset(shift, 0);

        bool isVisible(double radius) {
          if (_isVisible(
            screenRect: _screenRect,
            center: center,
            radiusInPixel: radius,
          )) {
            return result = true;
          }
          return false;
        }

        if (isVisible(radiusWithoutBorder)) {
          points[circle.color] ??= {};
          points[circle.color]![radiusWithoutBorder] ??= [];
          points[circle.color]![radiusWithoutBorder]!.add(center);
        }

        if (circle.borderStrokeWidth > 0 && isVisible(radiusWithBorder)) {
          // Check if color have some transparency or not
          // As drawPoints is more efficient than drawCircle
          if (circle.color.a == 1) {
            pointsFilledBorder[circle.borderColor] ??= {};
            pointsFilledBorder[circle.borderColor]![radiusWithBorder] ??= [];
            pointsFilledBorder[circle.borderColor]![radiusWithBorder]!
                .add(center);
          } else {
            final borderStrokeWidth = radiusWithBorder - radiusWithoutBorder;
            final radiusForBorder = radiusWithoutBorder + borderStrokeWidth / 2;
            pointsBorder[circle.borderColor] ??= {};
            pointsBorder[circle.borderColor]![borderStrokeWidth] ??= {};
            pointsBorder[circle.borderColor]![borderStrokeWidth]![
                radiusForBorder] ??= [];
            pointsBorder[circle.borderColor]![borderStrokeWidth]![
                    radiusForBorder]!
                .add(center);
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

    // First, the border when with non opaque disk
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

  Offset _getOffset(LatLng pos) => camera.getOffsetFromOrigin(pos);

  double _getRadiusInPixel(CircleMarker circle, double radius) =>
      circle.useRadiusInMeter
          ? (_getOffset(circle.point) -
                  _getOffset(_distance.offset(circle.point, radius, 180)))
              .distance
          : radius;

  /// Returns true if a centered circle with this radius is on the screen.
  bool _isVisible({
    required Rect screenRect,
    required Offset center,
    required double radiusInPixel,
  }) =>
      screenRect.overlaps(
        Rect.fromCircle(center: center, radius: radiusInPixel),
      );

  double _getWorldWidth() => camera.getWorldWidthAtZoom();
}
