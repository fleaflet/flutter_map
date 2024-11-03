part of 'polyline_layer.dart';

/// [CustomPainter] for [Polyline]s.
base class _PolylinePainter<R extends Object>
    extends HitDetectablePainter<R, _ProjectedPolyline<R>>
    with HitTestRequiresCameraOrigin {
  /// Reference to the list of [Polyline]s.
  final List<_ProjectedPolyline<R>> polylines;

  final double minimumHitbox;

  /// Create a new [_PolylinePainter] instance
  _PolylinePainter({
    required this.polylines,
    required this.minimumHitbox,
    required super.camera,
    required super.hitNotifier,
  });

  @override
  bool elementHitTest(
    _ProjectedPolyline<R> projectedPolyline, {
    required math.Point<double> point,
    required LatLng coordinate,
  }) {
    final polyline = projectedPolyline.polyline;

    // TODO: We should check the bounding box here, for efficiency
    // However, we need to account for:
    //  * map rotation
    //  * extended bbox that accounts for `minimumHitbox`
    //
    // if (!polyline.boundingBox.contains(touch)) {
    //   continue;
    // }

    final offsets = getOffsetsXY(
      camera: camera,
      origin: hitTestCameraOrigin,
      points: projectedPolyline.points,
    );
    final strokeWidth = polyline.useStrokeWidthInMeter
        ? _metersToStrokeWidth(
            hitTestCameraOrigin,
            _unproject(projectedPolyline.points.first),
            offsets.first,
            polyline.strokeWidth,
          )
        : polyline.strokeWidth;
    final hittableDistance = math.max(
      strokeWidth / 2 + polyline.borderStrokeWidth / 2,
      minimumHitbox,
    );

    for (int i = 0; i < offsets.length - 1; i++) {
      final o1 = offsets[i];
      final o2 = offsets[i + 1];

      final distanceSq =
          getSqSegDist(point.x, point.y, o1.dx, o1.dy, o2.dx, o2.dy);

      if (distanceSq <= hittableDistance * hittableDistance) return true;
    }

    return false;
  }

  @override
  Iterable<_ProjectedPolyline<R>> get elements => polylines;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    var path = ui.Path();
    var borderPath = ui.Path();
    var filterPath = ui.Path();
    var paint = Paint();
    var needsLayerSaving = false;

    Paint? borderPaint;
    Paint? filterPaint;
    int? lastHash;

    void drawPaths() {
      final hasBorder = borderPaint != null && filterPaint != null;
      if (hasBorder) {
        if (needsLayerSaving) {
          canvas.saveLayer(rect, Paint());
        }

        canvas.drawPath(borderPath, borderPaint!);
        borderPath = ui.Path();
        borderPaint = null;

        if (needsLayerSaving) {
          canvas.drawPath(filterPath, filterPaint!);
          filterPath = ui.Path();
          filterPaint = null;

          canvas.restore();
        }
      }

      canvas.drawPath(path, paint);
      path = ui.Path();
      paint = Paint();
    }

    final origin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final projectedPolyline in polylines) {
      final polyline = projectedPolyline.polyline;
      final offsets = getOffsetsXY(
        camera: camera,
        origin: origin,
        points: projectedPolyline.points,
      );
      if (offsets.isEmpty) {
        continue;
      }

      final hash = polyline.renderHashCode;
      if (needsLayerSaving || (lastHash != null && lastHash != hash)) {
        drawPaths();
      }
      lastHash = hash;
      needsLayerSaving = polyline.color.opacity < 1.0 ||
          (polyline.gradientColors?.any((c) => c.opacity < 1.0) ?? false);

      // strokeWidth, or strokeWidth + borderWidth if relevant.
      late double largestStrokeWidth;

      late final double strokeWidth;
      if (polyline.useStrokeWidthInMeter) {
        strokeWidth = _metersToStrokeWidth(
          origin,
          _unproject(projectedPolyline.points.first),
          offsets.first,
          polyline.strokeWidth,
        );
      } else {
        strokeWidth = polyline.strokeWidth;
      }
      largestStrokeWidth = strokeWidth;

      final isSolid = polyline.pattern == const StrokePattern.solid();
      final isDashed = polyline.pattern.segments != null;
      final isDotted = polyline.pattern.spacingFactor != null;

      paint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = polyline.strokeCap
        ..strokeJoin = polyline.strokeJoin
        ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;

      if (polyline.gradientColors == null) {
        paint.color = polyline.color;
      } else {
        polyline.gradientColors!.isNotEmpty
            ? paint.shader = _paintGradient(polyline, offsets)
            : paint.color = polyline.color;
      }

      if (polyline.borderStrokeWidth > 0.0) {
        // Outlined lines are drawn by drawing a thicker path underneath, then
        // stenciling the middle (in case the line fill is transparent), and
        // finally drawing the line fill.
        largestStrokeWidth = strokeWidth + polyline.borderStrokeWidth;
        borderPaint = Paint()
          ..color = polyline.borderColor
          ..strokeWidth = strokeWidth + polyline.borderStrokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.srcOver;

        filterPaint = Paint()
          ..color = polyline.borderColor.withAlpha(255)
          ..strokeWidth = strokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.dstOut;
      }

      final radius = paint.strokeWidth / 2;
      final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;

      final List<ui.Path> paths = [];
      if (borderPaint != null && filterPaint != null) {
        paths.add(borderPath);
        paths.add(filterPath);
      }
      paths.add(path);
      if (isSolid) {
        final SolidPixelHiker hiker = SolidPixelHiker(
          offsets: offsets,
          closePath: false,
          canvasSize: size,
          strokeWidth: largestStrokeWidth,
        );
        hiker.addAllVisibleSegments(paths);
      } else if (isDotted) {
        final DottedPixelHiker hiker = DottedPixelHiker(
          offsets: offsets,
          stepLength: strokeWidth * polyline.pattern.spacingFactor!,
          patternFit: polyline.pattern.patternFit!,
          closePath: false,
          canvasSize: size,
          strokeWidth: largestStrokeWidth,
        );

        final List<double> radii = [];
        if (borderPaint != null && filterPaint != null) {
          radii.add(borderRadius);
          radii.add(radius);
        }
        radii.add(radius);

        for (final visibleDot in hiker.getAllVisibleDots()) {
          for (int i = 0; i < paths.length; i++) {
            paths[i]
                .addOval(Rect.fromCircle(center: visibleDot, radius: radii[i]));
          }
        }
      } else if (isDashed) {
        final DashedPixelHiker hiker = DashedPixelHiker(
          offsets: offsets,
          segmentValues: polyline.pattern.segments!,
          patternFit: polyline.pattern.patternFit!,
          closePath: false,
          canvasSize: size,
          strokeWidth: largestStrokeWidth,
        );

        for (final visibleSegment in hiker.getAllVisibleSegments()) {
          for (final path in paths) {
            path.moveTo(visibleSegment.begin.dx, visibleSegment.begin.dy);
            path.lineTo(visibleSegment.end.dx, visibleSegment.end.dy);
          }
        }
      }
    }

    drawPaths();
  }

  ui.Gradient _paintGradient(Polyline polyline, List<Offset> offsets) =>
      ui.Gradient.linear(offsets.first, offsets.last, polyline.gradientColors!,
          _getColorsStop(polyline));

  List<double>? _getColorsStop(Polyline polyline) =>
      (polyline.colorsStop != null &&
              polyline.colorsStop!.length == polyline.gradientColors!.length)
          ? polyline.colorsStop
          : _calculateColorsStop(polyline);

  List<double> _calculateColorsStop(Polyline polyline) {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!
        .map((gradientColor) =>
            polyline.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  double _metersToStrokeWidth(
    Offset origin,
    LatLng p0,
    Offset o0,
    double strokeWidthInMeters,
  ) {
    final r = _distance.offset(p0, strokeWidthInMeters, 180);
    final delta = o0 - getOffset(camera, origin, r);
    return delta.distance;
  }

  LatLng _unproject(DoublePoint p0) =>
      camera.crs.projection.unprojectXY(p0.x, p0.y);

  @override
  bool shouldRepaint(_PolylinePainter<R> oldDelegate) =>
      polylines != oldDelegate.polylines ||
      camera != oldDelegate.camera ||
      hitNotifier != oldDelegate.hitNotifier ||
      minimumHitbox != oldDelegate.minimumHitbox;
}

const _distance = Distance();
