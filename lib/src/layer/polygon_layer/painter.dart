part of 'polygon_layer.dart';

/// The [_PolygonPainter] class is used to render [Polygon]s for
/// the [PolygonLayer].
class _PolygonPainter<R extends Object> extends CustomPainter {
  /// Reference to the list of [_ProjectedPolygon]s
  final List<_ProjectedPolygon<R>> polygons;

  /// Triangulated [polygons] if available
  ///
  /// Expected to be in same/corresponding order as [polygons].
  final List<List<int>?>? triangles;

  /// Reference to the [MapCamera].
  final MapCamera camera;

  /// Reference to the bounding box of the [Polygon].
  final LatLngBounds bounds;

  /// Whether to draw per-polygon labels
  final bool polygonLabels;

  /// Whether to draw labels last and thus over all the polygons
  final bool drawLabelsLast;

  /// See [PolylineLayer.hitNotifier]
  final LayerHitNotifier<R>? hitNotifier;

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  /// Create a new [_PolygonPainter] instance.
  _PolygonPainter({
    required this.polygons,
    required this.triangles,
    required this.camera,
    required this.polygonLabels,
    required this.drawLabelsLast,
    required this.hitNotifier,
  }) : bounds = camera.visibleBounds;

  @override
  bool? hitTest(Offset position) {
    _hits.clear();
    bool hasHit = false;

    final origin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;
    final point = position.toPoint();
    final coordinate = camera.pointToLatLng(point);

    for (final projectedPolygon in polygons.reversed) {
      final polygon = projectedPolygon.polygon;
      if ((hasHit && polygon.hitValue == null) ||
          !polygon.boundingBox.contains(coordinate)) {
        continue;
      }

      final projectedCoords = getOffsetsXY(
        camera: camera,
        origin: origin,
        points: projectedPolygon.points,
      ).toList();

      if (projectedCoords.first != projectedCoords.last) {
        projectedCoords.add(projectedCoords.first);
      }

      final hasHoles = projectedPolygon.holePoints.isNotEmpty;
      late final List<List<Offset>> projectedHoleCoords;
      if (hasHoles) {
        projectedHoleCoords = projectedPolygon.holePoints
            .map(
              (points) => getOffsetsXY(
                camera: camera,
                origin: origin,
                points: points,
              ).toList(),
            )
            .toList();

        if (projectedHoleCoords.firstOrNull != projectedHoleCoords.lastOrNull) {
          projectedHoleCoords.add(projectedHoleCoords.first);
        }
      }

      final isInPolygon = _isPointInPolygon(position, projectedCoords);
      late final isInHole = hasHoles &&
          projectedHoleCoords
              .map((c) => _isPointInPolygon(position, c))
              .any((e) => e);

      // Second check handles case where polygon outline intersects a hole,
      // ensuring that the hit matches with the visual representation
      if ((isInPolygon && !isInHole) || (!isInPolygon && isInHole)) {
        if (polygon.hitValue != null) _hits.add(polygon.hitValue!);
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
    final trianglePoints = <Offset>[];

    final filledPath = Path();
    final borderPath = Path();
    Polygon? lastPolygon;
    int? lastHash;

    // This functions flushes the batched fill and border paths constructed below
    void drawPaths() {
      if (lastPolygon == null) return;
      final polygon = lastPolygon!;

      // Draw filled polygon
      // ignore: deprecated_member_use_from_same_package
      if (polygon.isFilled ?? true) {
        if (polygon.color case final color?) {
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
          } else {
            canvas.drawPath(filledPath, paint);
          }
        }
      }

      // Draw polygon outline
      if (polygon.borderStrokeWidth > 0) {
        canvas.drawPath(borderPath, _getBorderPaint(polygon));
      }

      trianglePoints.clear();
      filledPath.reset();

      borderPath.reset();

      lastPolygon = null;
      lastHash = null;
    }

    final origin = (camera.project(camera.center) - camera.size / 2).toOffset();

    // Main loop constructing batched fill and border paths from given polygons.
    for (int i = 0; i <= polygons.length - 1; i++) {
      final projectedPolygon = polygons[i];
      if (projectedPolygon.points.isEmpty) continue;
      final polygon = projectedPolygon.polygon;

      final polygonTriangles = triangles?[i];

      final fillOffsets = getOffsetsXY(
        camera: camera,
        origin: origin,
        points: projectedPolygon.points,
        holePoints:
            polygonTriangles != null ? projectedPolygon.holePoints : null,
      );

      // The hash is based on the polygons visual properties. If the hash from
      // the current and the previous polygon no longer match, we need to flush
      // the batch previous polygons.
      final hash = polygon.renderHashCode;
      if (lastHash != hash) {
        drawPaths();
      }
      lastPolygon = polygon;
      lastHash = hash;

      // First add fills and borders to path.
      // ignore: deprecated_member_use_from_same_package
      if (polygon.isFilled ?? true) {
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
      }

      if (polygon.borderStrokeWidth > 0.0) {
        _addBorderToPath(
          borderPath,
          polygon,
          getOffsetsXY(
            camera: camera,
            origin: origin,
            points: projectedPolygon.points,
          ),
          size,
          canvas,
          _getBorderPaint(polygon),
          polygon.borderStrokeWidth,
        );
      }

      // Afterwards deal with more complicated holes.
      final holePointsList = polygon.holePointsList;
      if (holePointsList != null && holePointsList.isNotEmpty) {
        // Ideally we'd use `Path.combine(PathOperation.difference, ...)`
        // instead of evenOdd fill-type, however it creates visual artifacts
        // using the web renderer.
        filledPath.fillType = PathFillType.evenOdd;

        final holeOffsetsList = List<List<Offset>>.generate(
          holePointsList.length,
          (i) => getOffsets(camera, origin, holePointsList[i]),
          growable: false,
        );

        for (final holeOffsets in holeOffsetsList) {
          filledPath.addPolygon(holeOffsets, true);
        }

        if (!polygon.disableHolesBorder && polygon.borderStrokeWidth > 0.0) {
          _addHoleBordersToPath(borderPath, polygon, holeOffsetsList, size,
              canvas, _getBorderPaint(polygon), polygon.borderStrokeWidth);
        }
      }

      if (!drawLabelsLast && polygonLabels && polygon.textPainter != null) {
        // Labels are expensive because:
        //  * they themselves cannot easily be pulled into our batched path
        //    painting with the given text APIs
        //  * therefore, they require us to flush the batch of polygon draws to
        //    ensure polygons and labels are stacked correctly, i.e.:
        //    p1, p1_label, p2, p2_label, ... .

        // The painter will be null if the layOuting algorithm determined that
        // there isn't enough space.
        final painter = _buildLabelTextPainter(
          mapSize: camera.size,
          placementPoint: getOffset(camera, origin, polygon.labelPosition),
          bounds: _getBounds(origin, polygon),
          textPainter: polygon.textPainter!,
          rotationRad: camera.rotationRad,
          rotate: polygon.rotateLabel,
          padding: 20,
        );

        if (painter != null) {
          // Flush the batch before painting to preserve stacking.
          drawPaths();

          painter(canvas);
        }
      }
    }

    drawPaths();

    if (polygonLabels && drawLabelsLast) {
      for (final projectedPolygon in polygons) {
        if (projectedPolygon.points.isEmpty) {
          continue;
        }
        final polygon = projectedPolygon.polygon;
        final textPainter = polygon.textPainter;
        if (textPainter != null) {
          final painter = _buildLabelTextPainter(
            mapSize: camera.size,
            placementPoint: getOffset(camera, origin, polygon.labelPosition),
            bounds: _getBounds(origin, polygon),
            textPainter: textPainter,
            rotationRad: camera.rotationRad,
            rotate: polygon.rotateLabel,
            padding: 20,
          );

          painter?.call(canvas);
        }
      }
    }
  }

  Paint _getBorderPaint(Polygon polygon) {
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
    double strokeWidth,
  ) {
    final isSolid = polygon.pattern == const StrokePattern.solid();
    final isDashed = polygon.pattern.segments != null;
    final isDotted = polygon.pattern.spacingFactor != null;
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
        stepLength: polygon.borderStrokeWidth * polygon.pattern.spacingFactor!,
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

  void _addHoleBordersToPath(
    Path path,
    Polygon polygon,
    List<List<Offset>> holeOffsetsList,
    Size canvasSize,
    Canvas canvas,
    Paint paint,
    double strokeWidth,
  ) {
    for (final offsets in holeOffsetsList) {
      _addBorderToPath(
        path,
        polygon,
        offsets,
        canvasSize,
        canvas,
        paint,
        strokeWidth,
      );
    }
  }

  ({Offset min, Offset max}) _getBounds(Offset origin, Polygon polygon) {
    final bBox = polygon.boundingBox;
    return (
      min: getOffset(camera, origin, bBox.southWest),
      max: getOffset(camera, origin, bBox.northEast),
    );
  }

  /// Checks whether point [p] is within the specified closed [polygon]
  ///
  /// Uses the even-odd algorithm.
  static bool _isPointInPolygon(Offset p, List<Offset> polygon) {
    bool isInPolygon = false;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((((polygon[i].dy <= p.dy) && (p.dy < polygon[j].dy)) ||
              ((polygon[j].dy <= p.dy) && (p.dy < polygon[i].dy))) &&
          (p.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (p.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) isInPolygon = !isInPolygon;
    }
    return isInPolygon;
  }

  @override
  bool shouldRepaint(_PolygonPainter<R> oldDelegate) =>
      polygons != oldDelegate.polygons ||
      triangles != oldDelegate.triangles ||
      camera != oldDelegate.camera ||
      bounds != oldDelegate.bounds ||
      drawLabelsLast != oldDelegate.drawLabelsLast ||
      polygonLabels != oldDelegate.polygonLabels ||
      hitNotifier != oldDelegate.hitNotifier;
}
