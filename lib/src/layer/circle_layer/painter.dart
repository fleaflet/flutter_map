part of 'circle_layer.dart';

/// The [CustomPainter] used to draw [CircleMarker]s for the [CircleLayer].
class CirclePainter<R extends Object> extends CustomPainter
    with HitDetectablePainter<R, CircleMarker<R>>, FeatureLayerUtils {
  /// Reference to the list of [CircleMarker]s of the [CircleLayer].
  final List<CircleMarker<R>> circles;

  @override
  final MapCamera camera;

  @override
  final LayerHitNotifier<R>? hitNotifier;

  /// If true, we reuse the same "meter in pixels" computation for all circles.
  final bool optimizeRadiusInMeters;

  /// Create a [CirclePainter] instance by providing the required
  /// reference objects.
  CirclePainter({
    required this.circles,
    required this.camera,
    required this.hitNotifier,
    required this.optimizeRadiusInMeters,
  });

  @override
  bool elementHitTest(
    CircleMarker<R> element, {
    required Offset point,
    required LatLng coordinate,
  }) {
    final radius = _getRadiusInPixel(element) + element.borderStrokeWidth / 2;
    final initialCenter = _getOffset(element.point);

    WorldWorkControl checkIfHit(double shift) {
      final center = initialCenter + Offset(shift, 0);
      if (!_isVisible(center: center, radiusInPixel: radius)) {
        return WorldWorkControl.invisible;
      }

      return pow(point.dx - center.dx, 2) + pow(point.dy - center.dy, 2) <=
              radius * radius
          ? WorldWorkControl.hit
          : WorldWorkControl.visible;
    }

    return workAcrossWorlds(checkIfHit);
  }

  @override
  Iterable<CircleMarker<R>> get elements => circles;

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    canvas.clipRect(viewportRect);

    // Let's calculate all the points grouped by color and radius
    final points = <Color, Map<double, List<Offset>>>{};
    final pointsFilledBorder = <Color, Map<double, List<Offset>>>{};
    final pointsBorder = <Color, Map<double, Map<double, List<Offset>>>>{};
    _pixelsPerMeter = null;
    for (final circle in circles) {
      final radiusWithoutBorder = _getRadiusInPixel(circle);
      final radiusWithBorder =
          radiusWithoutBorder + circle.borderStrokeWidth / 2;
      final initialCenter = _getOffset(circle.point);

      /// Draws on a "single-world"
      WorldWorkControl drawIfVisible(double shift) {
        WorldWorkControl result = WorldWorkControl.invisible;
        final center = initialCenter + Offset(shift, 0);

        bool isVisible(double radius) {
          if (_isVisible(center: center, radiusInPixel: radius)) {
            result = WorldWorkControl.visible;
            return true;
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
            pointsBorder[circle.borderColor] ??= {};
            pointsBorder[circle.borderColor]![circle.borderStrokeWidth] ??= {};
            pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
                radiusWithoutBorder] ??= [];
            pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
                    radiusWithoutBorder]!
                .add(center);
          }
        }

        return result;
      }

      workAcrossWorlds(drawIfVisible);
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

    // Then the filled border in order to be under the disk
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

    // And then the disk
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

  // Cached number of pixels per meter.
  double? _pixelsPerMeter;

  double _getRadiusInPixel(CircleMarker circle) {
    if (!circle.useRadiusInMeter) {
      return circle.radius;
    }
    if (!optimizeRadiusInMeters) {
      return metersToScreenPixels(circle.point, circle.radius);
    }
    if (_pixelsPerMeter == null) {
      final result = metersToScreenPixels(circle.point, circle.radius);
      _pixelsPerMeter = result / circle.radius;
    }
    return _pixelsPerMeter! * circle.radius;
  }

  /// Returns true if a centered circle with this radius is on the screen.
  bool _isVisible({
    required Offset center,
    required double radiusInPixel,
  }) =>
      viewportRect
          .overlaps(Rect.fromCircle(center: center, radius: radiusInPixel));
}
