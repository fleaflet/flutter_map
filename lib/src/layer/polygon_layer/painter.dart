part of 'polygon_layer.dart';

/// The [_PolygonPainter] class is used to render [Polygon]s for
/// the [PolygonLayer].
base class _PolygonPainter<R extends Object>
    extends HitDetectablePainter<R, _ProjectedPolygon<R>>
    with HitTestRequiresCameraOrigin {
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

  /// Create a new [_PolygonPainter] instance.
  _PolygonPainter({
    required this.polygons,
    required this.triangles,
    required super.camera,
    required this.polygonLabels,
    required this.drawLabelsLast,
    required this.debugAltRenderer,
    required super.hitNotifier,
  }) : bounds = camera.visibleBounds;

  @override
  bool elementHitTest(
    _ProjectedPolygon<R> projectedPolygon, {
    required math.Point<double> point,
    required LatLng coordinate,
  }) {
    // TODO: We should check the bounding box here, for efficiency
    // However, we need to account for map rotation
    //
    // if (!polygon.boundingBox.contains(touch)) {
    //   continue;
    // }

    final projectedCoords = getOffsetsXY(
      camera: camera,
      origin: hitTestCameraOrigin,
      points: projectedPolygon.points,
    );
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
          origin: hitTestCameraOrigin,
          points: points,
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
    return (isInPolygon && !isInHole) || (!isInPolygon && isInHole);
  }

  @override
  Iterable<_ProjectedPolygon<R>> get elements => polygons;

  @override
  void paint(Canvas canvas, Size size) {
    const checkOpacity = true; // for debugging purposes only, should be true

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
      final opacity = polygon.color?.opacity ?? 0;
      if (lastHash != hash || (checkOpacity && opacity > 0 && opacity < 1)) {
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
      // Improper handling of opacity and fill methods may result in normal
      // polygons cutting holes into other polygons, when they should be mixing:
      // https://github.com/fleaflet/flutter_map/issues/1898.
      final holePointsList = polygon.holePointsList;
      if (holePointsList != null && holePointsList.isNotEmpty) {
        // See `Path.combine` comments below
        // Avoids failing to cut holes if the winding directions of the holes
        // and the normal points are the same
        filledPath.fillType = PathFillType.evenOdd;

        final holeOffsetsList = List<List<Offset>>.generate(
          holePointsList.length,
          (i) => getOffsets(camera, origin, holePointsList[i]),
          growable: false,
        );

        for (final holeOffsets in holeOffsetsList) {
          filledPath.addPolygon(holeOffsets, true);

          // TODO: Potentially more efficient and may change the need to do
          // opacity checking - needs testing. However,
          // https://github.com/flutter/flutter/issues/44572 prevents this.
          // Also need to verify if `xor` or `difference` is preferred.
          /*filledPath = Path.combine(
            PathOperation.xor,
            filledPath,
            Path()..addPolygon(holeOffsets, true),
          );*/
        }

        if (!polygon.disableHolesBorder && polygon.borderStrokeWidth > 0.0) {
          _addHoleBordersToPath(
            borderPath,
            polygon,
            holeOffsetsList,
            size,
            canvas,
            _getBorderPaint(polygon),
            polygon.borderStrokeWidth,
          );
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
