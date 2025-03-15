part of 'polygon_layer.dart';

/// The [CustomPainter] used to draw [Polygon]s for the [PolygonLayer].
// TODO: We should consider exposing this publicly, as with [CirclePainter] -
// but the projected objects are private at the moment.
class _PolygonPainter<R extends Object> extends CustomPainter
    with HitDetectablePainter<R, _ProjectedPolygon<R>>, FeatureLayerUtils {
  /// Reference to the list of [_ProjectedPolygon]s
  final List<_ProjectedPolygon<R>> polygons;

  /// Triangulated [polygons] if available
  ///
  /// Expected to be in same/corresponding order as [polygons].
  final List<List<int>?>? triangles;

  /// Reference to the bounding box of the [Polygon].
  final LatLngBounds bounds;

  /// Whether to draw per-polygon labels ([Polygon.label])
  ///
  /// Note that drawing labels will reduce performance, as the internal
  /// canvas must be drawn to and 'saved' more frequently to ensure the proper
  /// stacking order is maintained. This can be avoided, potentially at the
  /// expense of appearance, by setting [PolygonLayer.drawLabelsLast].
  ///
  /// It is safe to ignore this property, and the performance pitfalls described
  /// above, if no [Polygon]s have labels specified.
  final bool polygonLabels;

  /// Whether to draw labels last and thus over all the polygons
  ///
  /// This may improve performance: see [polygonLabels] for more information.
  final bool drawLabelsLast;

  /// See [PolygonLayer.debugAltRenderer]
  final bool debugAltRenderer;

  /// See [PolygonLayer.invertedFill]
  final Color? invertedFill;

  @override
  final MapCamera camera;

  @override
  final LayerHitNotifier<R>? hitNotifier;

  /// Create a new [_PolygonPainter] instance.
  _PolygonPainter({
    required this.polygons,
    required this.triangles,
    required this.polygonLabels,
    required this.drawLabelsLast,
    required this.debugAltRenderer,
    required this.camera,
    required this.invertedFill,
    required this.hitNotifier,
  }) : bounds = camera.visibleBounds;

  @override
  bool elementHitTest(
    _ProjectedPolygon<R> projectedPolygon, {
    required Offset point,
    required LatLng coordinate,
  }) {
    // TODO: We should check the bounding box here, for efficiency
    // However, we need to account for map rotation
    //
    // if (!polygon.boundingBox.contains(touch)) {
    //   continue;
    // }

    WorldWorkControl checkIfHit(double shift) {
      final projectedCoords = getOffsetsXY(
        camera: camera,
        origin: origin,
        points: projectedPolygon.points,
        shift: shift,
      );
      if (!areOffsetsVisible(projectedCoords)) {
        return WorldWorkControl.invisible;
      }

      if (projectedCoords.first != projectedCoords.last) {
        projectedCoords.add(projectedCoords.first);
      }

      final isValidPolygon = projectedCoords.length >= 3;
      final isInPolygon =
          isValidPolygon && isPointInPolygon(point, projectedCoords);

      final isInHole = projectedPolygon.holePoints.any(
        (points) {
          final projectedHoleCoords = getOffsetsXY(
            camera: camera,
            origin: origin,
            points: points,
            shift: shift,
          );
          if (projectedHoleCoords.first != projectedHoleCoords.last) {
            projectedHoleCoords.add(projectedHoleCoords.first);
          }

          final isValidHolePolygon = projectedHoleCoords.length >= 3;
          return isValidHolePolygon &&
              isPointInPolygon(point, projectedHoleCoords);
        },
      );

      // Second check handles case where polygon outline intersects a hole,
      // ensuring that the hit matches with the visual representation
      return (isInPolygon && !isInHole) || (!isInPolygon && isInHole)
          ? WorldWorkControl.hit
          : WorldWorkControl.visible;
    }

    return workAcrossWorlds(checkIfHit);
  }

  @override
  Iterable<_ProjectedPolygon<R>> get elements => polygons;

  static const _minMaxLatitude = [LatLng(90, 0), LatLng(-90, 0)];

  /// Whether to use `PathFillType.evenOdd` (true) or `Path.combine` (false)
  ///
  ///  * `Path.combine` doesn't work & isn't stable/consistent on web
  ///  * `evenOdd` gives broken results when polygons intersect when inverted
  ///
  /// The best option is to use `evenOdd` on web, as it at least works
  /// sometimes, and `Path.combine` otherwise, as it gives correct results on
  /// native platforms.
  ///
  /// See https://github.com/fleaflet/flutter_map/pull/2046.
  static const _useEvenOdd = kIsWeb;

  // Do we also remove the holes from the inverted map?
  // Should be `true`
  static const _invertedHoles = true;

  // Do we also fill the holes with inverted fill?
  // Should be `true`
  static const _fillInvertedHoles = true;

  @override
  void paint(Canvas canvas, Size size) {
    const checkOpacity = true; // for debugging purposes only, should be true
    super.paint(canvas, size);

    final trianglePoints = <Offset>[];

    Path filledPath = Path();
    final borderPath = Path();
    Color? lastColor;
    int? lastHash;
    Paint? borderPaint;

    // Draw polygon outline
    void drawBorders() {
      if (borderPaint != null) {
        canvas.drawPath(borderPath, borderPaint);
      }
      borderPath.reset();
      lastHash = null;
    }

    // This functions flushes the batched fill and border paths constructed below
    void drawPaths() {
      final Color? color = lastColor;
      if (color == null) {
        drawBorders();
        return;
      }

      // Draw filled polygon
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      if (trianglePoints.isNotEmpty) {
        final points = Float32List(trianglePoints.length * 2);
        for (int i = 0; i < trianglePoints.length; ++i) {
          points[i * 2] = trianglePoints[i].dx;
          points[i * 2 + 1] = trianglePoints[i].dy;
        }
        final vertices = Vertices.raw(VertexMode.triangles, points);
        canvas.drawVertices(vertices, BlendMode.src, paint);

        if (debugAltRenderer) {
          for (int i = 0; i < trianglePoints.length; i += 3) {
            canvas.drawCircle(
              trianglePoints[i],
              5,
              Paint()..color = const Color(0x7EFF0000),
            );
            canvas.drawCircle(
              trianglePoints[i + 1],
              5,
              Paint()..color = const Color(0x7E00FF00),
            );
            canvas.drawCircle(
              trianglePoints[i + 2],
              5,
              Paint()..color = const Color(0x7E0000FF),
            );

            final path = Path()
              ..addPolygon(
                [
                  trianglePoints[i],
                  trianglePoints[i + 1],
                  trianglePoints[i + 2],
                ],
                true,
              );

            canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0x7EFFFFFF)
                ..style = PaintingStyle.fill,
            );

            canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFF000000)
                ..style = PaintingStyle.stroke,
            );
          }
        }
      } else {
        canvas.drawPath(filledPath, paint);
      }

      trianglePoints.clear();
      filledPath.reset();

      lastColor = null;

      drawBorders();
    }

    /// Draws labels on a "single-world"
    WorldWorkControl drawLabelIfVisible(
      double shift,
      _ProjectedPolygon<R> projectedPolygon,
    ) {
      final polygon = projectedPolygon.polygon;
      final painter = _buildLabelTextPainter(
        mapSize: camera.size,
        placementPoint: getOffset(
          camera,
          origin,
          polygon.labelPosition,
          shift: shift,
        ),
        bounds: _getBounds(origin, polygon),
        textPainter: polygon.textPainter!,
        rotationRad: camera.rotationRad,
        rotate: polygon.rotateLabel,
        padding: 20,
      );
      if (painter == null) return WorldWorkControl.invisible;

      // Flush the batch before painting to preserve stacking.
      drawPaths();

      painter(canvas);
      return WorldWorkControl.visible;
    }

    Path holePaths = Path();

    void addPolygon(List<Offset> offsets) {
      // ignore: dead_code
      if (!_fillInvertedHoles) return;

      if (_useEvenOdd) {
        holePaths.addPolygon(offsets, true);
        return;
      }
      holePaths = Path.combine(
        PathOperation.union,
        holePaths,
        Path()..addPolygon(offsets, true),
      );
    }

    void removePolygon(List<Offset> offsets) {
      if (_useEvenOdd) {
        filledPath.fillType = PathFillType.evenOdd;
        filledPath.addPolygon(offsets, true);
        return;
      }
      filledPath = Path.combine(
        PathOperation.difference,
        filledPath,
        Path()..addPolygon(offsets, true),
      );
    }

    // Specific map treatment with `invertFill`.
    if (invertedFill != null) {
      filledPath.reset();
      final minMaxProjected =
          camera.crs.projection.projectList(_minMaxLatitude);
      final minMaxY = getOffsetsXY(
        camera: camera,
        origin: origin,
        points: minMaxProjected,
      );
      final maxX = viewportRect.right;
      final minX = viewportRect.left;
      final maxY = minMaxY[0].dy;
      final minY = minMaxY[1].dy;
      final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
      filledPath.addRect(rect);

      for (int i = 0; i <= polygons.length - 1; i++) {
        final projectedPolygon = polygons[i];
        if (projectedPolygon.points.isEmpty) continue;

        /// Draws each full polygon as a hole on a "single-world"
        WorldWorkControl drawPolygonAsHole(double shift) {
          final fillOffsets = getOffsetsXY(
            camera: camera,
            origin: origin,
            points: projectedPolygon.points,
            shift: shift,
          );
          if (!areOffsetsVisible(fillOffsets)) {
            return WorldWorkControl.invisible;
          }

          removePolygon(fillOffsets);

          if (_invertedHoles) {
            for (final singleHolePoints in projectedPolygon.holePoints) {
              final holeOffsets = getOffsetsXY(
                camera: camera,
                origin: origin,
                points: singleHolePoints,
                shift: shift,
              );
              removePolygon(holeOffsets);
              addPolygon(holeOffsets);
            }
          }
          return WorldWorkControl.visible;
        }

        workAcrossWorlds(drawPolygonAsHole);
      }

      // Draw filled map with polygons as holes
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = invertedFill!;

      canvas.drawPath(filledPath, paint);
      if (_fillInvertedHoles) {
        canvas.drawPath(holePaths, paint);
      }

      filledPath.reset();
    }

    for (int i = 0; i <= polygons.length - 1; i++) {
      final projectedPolygon = polygons[i];
      final polygon = projectedPolygon.polygon;
      if (projectedPolygon.points.isEmpty) continue;
      borderPaint = _getBorderPaint(polygon);

      final polygonTriangles = triangles?[i];

      /// Draws on a "single-world"
      WorldWorkControl drawIfVisible(double shift) {
        final fillOffsets = getOffsetsXY(
          camera: camera,
          origin: origin,
          points: projectedPolygon.points,
          holePoints:
              polygonTriangles != null ? projectedPolygon.holePoints : null,
          shift: shift,
        );
        if (!areOffsetsVisible(fillOffsets)) {
          return WorldWorkControl.invisible;
        }

        if (debugAltRenderer) {
          const offsetsLabelStyle = TextStyle(
            color: Color(0xFF000000),
            fontSize: 16,
          );

          for (int i = 0; i < fillOffsets.length; i++) {
            TextPainter(
              text: TextSpan(
                text: i.toString(),
                style: offsetsLabelStyle,
              ),
              textDirection: TextDirection.ltr,
            )
              ..layout(maxWidth: 100)
              ..paint(canvas, fillOffsets[i]);
          }
        }

        // The hash is based on the polygons visual properties. If the hash from
        // the current and the previous polygon no longer match, we need to flush
        // the batch previous polygons.
        // We also need to flush if the opacity is not 1 or 0, so that they get
        // mixed properly. Otherwise, holes get cut, or colors aren't mixed,
        // depending on the holes handler.
        final hash = polygon.renderHashCode;
        final opacity = polygon.color?.a ?? 0;
        if (lastHash != hash || (checkOpacity && opacity > 0 && opacity < 1)) {
          drawPaths();
        }
        lastColor = polygon.color;
        lastHash = hash;

        // First add fills and borders to path.
        if (polygon.color != null) {
          if (polygonTriangles != null) {
            final len = polygonTriangles.length;
            for (int i = 0; i < len; ++i) {
              trianglePoints.add(fillOffsets[polygonTriangles[i]]);
            }
          } else {
            filledPath.addPolygon(fillOffsets, true);
          }
        }

        void addBorderToPath(List<Offset> offsets) => _addBorderToPath(
              borderPath,
              polygon,
              offsets,
              size,
              canvas,
              borderPaint!,
            );

        if (borderPaint != null) {
          addBorderToPath(
            getOffsetsXY(
              camera: camera,
              origin: origin,
              points: projectedPolygon.points,
              shift: shift,
            ),
          );
        }

        // Afterwards deal with more complicated holes.
        // Improper handling of opacity and fill methods may result in normal
        // polygons cutting holes into other polygons, when they should be mixing:
        // https://github.com/fleaflet/flutter_map/issues/1898.
        for (final singleHolePoints in projectedPolygon.holePoints) {
          final holeOffsets = getOffsetsXY(
            camera: camera,
            origin: origin,
            points: singleHolePoints,
            shift: shift,
          );
          removePolygon(holeOffsets);
          if (!polygon.disableHolesBorder && borderPaint != null) {
            addBorderToPath(holeOffsets);
          }
        }

        return WorldWorkControl.visible;
      }

      workAcrossWorlds(drawIfVisible);

      if (!drawLabelsLast && polygonLabels && polygon.textPainter != null) {
        // Labels are expensive because:
        //  * they themselves cannot easily be pulled into our batched path
        //    painting with the given text APIs
        //  * therefore, they require us to flush the batch of polygon draws to
        //    ensure polygons and labels are stacked correctly, i.e.:
        //    p1, p1_label, p2, p2_label, ... .

        // The painter will be null if the layOuting algorithm determined that
        // there isn't enough space.
        workAcrossWorlds(
          (double shift) => drawLabelIfVisible(shift, projectedPolygon),
        );
      }
      drawPaths();
    }

    if (polygonLabels && drawLabelsLast) {
      for (final projectedPolygon in polygons) {
        if (projectedPolygon.points.isEmpty) {
          continue;
        }
        if (projectedPolygon.polygon.textPainter == null) {
          continue;
        }
        workAcrossWorlds(
          (double shift) => drawLabelIfVisible(shift, projectedPolygon),
        );
      }
    }
  }

  Paint? _getBorderPaint(Polygon polygon) {
    if (polygon.borderStrokeWidth <= 0) {
      return null;
    }
    final isDotted = polygon.pattern.spacingFactor != null;
    return Paint()
      ..color = polygon.borderColor
      ..strokeWidth = polygon.borderStrokeWidth
      ..strokeCap = polygon.strokeCap
      ..strokeJoin = polygon.strokeJoin
      ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke;
  }

  void _addBorderToPath(
    Path path,
    Polygon polygon,
    List<Offset> offsets,
    Size canvasSize,
    Canvas canvas,
    Paint paint,
  ) {
    final isSolid = polygon.pattern == const StrokePattern.solid();
    final isDashed = polygon.pattern.segments != null;
    final isDotted = polygon.pattern.spacingFactor != null;
    final strokeWidth = polygon.borderStrokeWidth;

    if (isSolid) {
      final SolidPixelHiker hiker = SolidPixelHiker(
        offsets: offsets,
        closePath: true,
        canvasSize: canvasSize,
        strokeWidth: strokeWidth,
      );
      hiker.addAllVisibleSegments([path]);
    } else if (isDotted) {
      final DottedPixelHiker hiker = DottedPixelHiker(
        offsets: offsets,
        stepLength: strokeWidth * polygon.pattern.spacingFactor!,
        patternFit: polygon.pattern.patternFit!,
        closePath: true,
        canvasSize: canvasSize,
        strokeWidth: strokeWidth,
      );
      for (final visibleDot in hiker.getAllVisibleDots()) {
        canvas.drawCircle(visibleDot, polygon.borderStrokeWidth / 2, paint);
      }
    } else if (isDashed) {
      final DashedPixelHiker hiker = DashedPixelHiker(
        offsets: offsets,
        segmentValues: polygon.pattern.segments!,
        patternFit: polygon.pattern.patternFit!,
        closePath: true,
        canvasSize: canvasSize,
        strokeWidth: strokeWidth,
      );

      for (final visibleSegment in hiker.getAllVisibleSegments()) {
        path.moveTo(visibleSegment.begin.dx, visibleSegment.begin.dy);
        path.lineTo(visibleSegment.end.dx, visibleSegment.end.dy);
      }
    }
  }

  ({Offset min, Offset max}) _getBounds(Offset origin, Polygon polygon) {
    final bBox = polygon.boundingBox;
    return (
      min: getOffset(camera, origin, bBox.southWest),
      max: getOffset(camera, origin, bBox.northEast),
    );
  }

  @override
  bool shouldRepaint(_PolygonPainter<R> oldDelegate) =>
      polygons != oldDelegate.polygons ||
      triangles != oldDelegate.triangles ||
      camera != oldDelegate.camera ||
      bounds != oldDelegate.bounds ||
      invertedFill != oldDelegate.invertedFill ||
      drawLabelsLast != oldDelegate.drawLabelsLast ||
      polygonLabels != oldDelegate.polygonLabels ||
      hitNotifier != oldDelegate.hitNotifier;
}
