part of 'polyline_layer.dart';

/// [CustomPainter] for [Polygon]s.
class _PolylinePainter<R extends Object> extends CustomPainter {
  /// Reference to the list of [Polyline]s.
  final List<_ProjectedPolyline<R>> polylines;

  /// Reference to the [MapCamera].
  final MapCamera camera;
  final LayerHitNotifier<R>? hitNotifier;
  final double minimumHitbox;

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  /// Create a new [_PolylinePainter] instance
  _PolylinePainter({
    required this.polylines,
    required this.camera,
    required this.hitNotifier,
    required this.minimumHitbox,
  });

  @override
  bool? hitTest(Offset position) {
    _hits.clear();
    bool hasHit = false;

    final origin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final projectedPolyline in polylines.reversed) {
      final polyline = projectedPolyline.polyline;
      if (hasHit && polyline.hitValue == null) continue;

      // TODO: For efficiency we'd ideally filter by bounding box here. However
      // we'd need to compute an extended bounding box that accounts account for
      // the `borderStrokeWidth` & the `minimumHitbox`
      // if (!polyline.boundingBox.contains(touch)) {
      //   continue;
      // }

      final offsets = getOffsetsXY(
        camera: camera,
        origin: origin,
        points: projectedPolyline.points,
      );
      final strokeWidth = polyline.useStrokeWidthInMeter
          ? _metersToStrokeWidth(
              origin,
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
            getSqSegDist(position.dx, position.dy, o1.dx, o1.dy, o2.dx, o2.dy);

        if (distanceSq <= hittableDistance * hittableDistance) {
          if (polyline.hitValue != null) _hits.add(polyline.hitValue!);
          hasHit = true;
          break;
        }
      }
    }

    if (!hasHit) {
      hitNotifier?.value = null;
      return false;
    }

    final point = position.toPoint();
    hitNotifier?.value = LayerHitResult(
      hitValues: _hits,
      coordinate: camera.pointToLatLng(point),
      point: point,
    );
    return true;
  }

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

      if (isDotted) {
        final spacing = strokeWidth * polyline.pattern.spacingFactor!;
        if (borderPaint != null && filterPaint != null) {
          _paintDottedLine(
              borderPath, offsets, borderRadius, spacing, polyline.pattern);
          _paintDottedLine(
              filterPath, offsets, radius, spacing, polyline.pattern);
        }
        _paintDottedLine(path, offsets, radius, spacing, polyline.pattern);
      } else if (isDashed) {
        if (borderPaint != null && filterPaint != null) {
          _paintDashedLine(borderPath, offsets, polyline.pattern);
          _paintDashedLine(filterPath, offsets, polyline.pattern);
        }
        _paintDashedLine(path, offsets, polyline.pattern);
      } else {
        if (borderPaint != null && filterPaint != null) {
          _paintLine(borderPath, offsets);
          _paintLine(filterPath, offsets);
        }
        _paintLine(path, offsets);
      }
    }

    drawPaths();
  }

  void _paintDottedLine(
    ui.Path path,
    List<Offset> offsets,
    double radius,
    double stepLength,
    PolylinePattern pattern,
  ) {
    final PatternFit patternFit = pattern.patternFit!;

    if (offsets.isEmpty) return;

    if (offsets.length == 1) {
      path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
      return;
    }

    int offsetIndex = 0;

    Offset offset0 = offsets[offsetIndex++];
    Offset offset1 = offsets[offsetIndex++];

    final double factor = _MyDistanceManager.getDottedFactor(
      offsets,
      stepLength,
      pattern.patternFit!,
    );

    final _MyDistanceManager manager = _MyDistanceManager(factor: factor);
    manager.remaining = stepLength;
    path.addOval(Rect.fromCircle(center: offsets.first, radius: radius));
    while (true) {
      final Offset newOffset = manager.getDistanceOffset(offset0, offset1);

      if (manager.goToNewOffsetIndex) {
        if (offsetIndex >= offsets.length) {
          if (patternFit != PatternFit.none) {
            path.addOval(Rect.fromCircle(center: newOffset, radius: radius));
          }
          return;
        }
        offset0 = offset1;
        offset1 = offsets[offsetIndex++];
      } else {
        offset0 = newOffset;
      }
      if (manager.remaining == 0) {
        path.addOval(Rect.fromCircle(center: newOffset, radius: radius));
        manager.remaining = stepLength;
      }
    }
  }

  /// Returns true if the last point was a space.
  ///
  /// We may need that info if we want to do something special when the last
  /// point was not displayed, like putting artificially a dot at this location.
  void _paintDashedLine(
    ui.Path path,
    List<Offset> offsets,
    PolylinePattern pattern,
  ) {
    final List<double> dashValues = pattern.segments!;
    final PatternFit patternFit = pattern.patternFit!;

    if (offsets.length < 2 ||
        dashValues.length < 2 ||
        dashValues.length.isOdd) {
      return;
    }

    int dashValueIndex = 0;
    int offsetIndex = 0;

    Offset offset0 = offsets[offsetIndex++];
    Offset offset1 = offsets[offsetIndex++];

    final double factor = _MyDistanceManager.getDashFactor(
      offsets,
      dashValues,
      patternFit,
    );

    final _MyDistanceManager manager = _MyDistanceManager(factor: factor);
    manager.remaining = dashValues[dashValueIndex];
    path.moveTo(offset0.dx, offset0.dy);
    while (true) {
      final Offset newOffset = manager.getDistanceOffset(offset0, offset1);

      if (dashValueIndex.isEven) {
        path.lineTo(newOffset.dx, newOffset.dy);
      } else {
        // TODO optim: remove useless `moveTo`s, potentially many of them
        path.moveTo(newOffset.dx, newOffset.dy);
      }

      if (manager.goToNewOffsetIndex) {
        // was it the last point?
        if (offsetIndex >= offsets.length) {
          if (dashValueIndex.isOdd) {
            // Were we on a "space-dash"?
            if (patternFit == PatternFit.appendDot) {
              // Add a dot at the new point.
              // No requirement to move to the new point before painting,
              // because that already occurs above.
              // path.moveTo(newOffset.dx, newOffset.dy);
              path.lineTo(newOffset.dx, newOffset.dy);
            } else if (patternFit == PatternFit.extendFinalDash) {
              // Move back to the end of the last dash, and extend it to the
              // new point.
              // Because there is no `saveLayer` operation between the painting
              // of the previous dash and this segment, correct opacity rules
              // are preserved, despite this being a new segment which
              // technically overlaps with the previous one, and so the visual
              // appearance is correct.
              path.moveTo(offset0.dx, offset0.dy);
              path.lineTo(newOffset.dx, newOffset.dy);
            }
          }
          return;
        }
        offset0 = offset1;
        offset1 = offsets[offsetIndex++];
      } else {
        offset0 = newOffset;
      }
      if (manager.remaining == 0) {
        dashValueIndex++;
        manager.remaining = dashValues[dashValueIndex % dashValues.length];
      }
    }
  }

  void _paintLine(ui.Path path, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return;
    }
    path.addPolygon(offsets, false);
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

class _MyDistanceManager {
  /// Factor to be used on offset distances.
  final double factor;

  _MyDistanceManager({required this.factor});

  /// Pixel length remaining.
  late double remaining;

  bool _nextOffsetPlease = false;

  bool get goToNewOffsetIndex {
    if (_nextOffsetPlease) {
      _nextOffsetPlease = false;
      return true;
    }
    return false;
  }

  /// Returns the offset on segment [A,B] that matches the remaining distance.
  Offset getDistanceOffset(final Offset offsetA, final Offset offsetB) {
    final segmentDistance = factor * (offsetA - offsetB).distance;
    if (remaining >= segmentDistance) {
      remaining -= segmentDistance;
      _nextOffsetPlease = true;
      return offsetB;
    }
    final fB = remaining / segmentDistance;
    final fA = 1.0 - fB;
    remaining = 0;
    return Offset(
      offsetA.dx * fA + offsetB.dx * fB,
      offsetA.dy * fA + offsetB.dy * fB,
    );
  }

  static double _getPolylinePixelDistance(List<Offset> offsets) {
    double result = 0;
    if (offsets.length < 2) {
      return result;
    }
    for (int i = 1; i < offsets.length; i++) {
      final Offset offsetA = offsets[i - 1];
      final Offset offsetB = offsets[i];
      result += (offsetA - offsetB).distance;
    }
    return result;
  }

  static double getDottedFactor(
    List<Offset> offsets,
    double stepLength,
    PatternFit patternFit,
  ) {
    if (patternFit == PatternFit.scale) {
      final double polylinePixelDistance = _getPolylinePixelDistance(offsets);
      if (polylinePixelDistance == 0) {
        return 0;
      }
      final int times = (polylinePixelDistance / stepLength).ceil();
      return (times * stepLength) / polylinePixelDistance;
    }

    return 1;
  }

  /// Returns the factor for offset distances so that the dash pattern fits.
  ///
  /// The idea is that we need to be able to display the dash pattern completely
  /// n times (at least once), plus once the initial dash segment. That's the
  /// way we deal with the "ending" side-effect.
  static double getDashFactor(
    List<Offset> offsets,
    List<double> dashValues,
    PatternFit patternFit,
  ) {
    double getTotalDashDistance(List<double> dashValues) {
      double result = 0;
      for (final double value in dashValues) {
        result += value;
      }
      return result;
    }

    if (patternFit == PatternFit.scale) {
      final double polylinePixelDistance = _getPolylinePixelDistance(offsets);
      if (polylinePixelDistance == 0) {
        return 0;
      }
      final double totalDashDistance = getTotalDashDistance(dashValues);
      final double firstDashDistance = dashValues.first;
      final int times = (polylinePixelDistance / totalDashDistance).ceil();
      return (times * totalDashDistance + firstDashDistance) /
          polylinePixelDistance;
    }

    return 1;
  }
}
