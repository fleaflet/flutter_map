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

  // OutCodes for the Cohen-Sutherland algorithm
  static const _csInside = 0; // 0000
  static const _csLeft = 1; // 0001
  static const _csRight = 2; // 0010
  static const _csBottom = 4; // 0100
  static const _csTop = 8; // 1000

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
          _getBorderPaint(polygon),
          canvas,
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
              canvas, _getBorderPaint(polygon));
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
    final isDotted = polygon.isDotted;
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
    Paint paint,
    Canvas canvas,
  ) {
    if (polygon.isDotted) {
      final borderRadius = polygon.borderStrokeWidth / 2;
      final spacing = polygon.borderStrokeWidth * 1.5;
      _addDottedLineToPath(
          canvas, paint, offsets, borderRadius, spacing, canvasSize);
    } else {
      _addLineToPath(path, offsets);
    }
  }

  void _addHoleBordersToPath(
    Path path,
    Polygon polygon,
    List<List<Offset>> holeOffsetsList,
    Size canvasSize,
    Canvas canvas,
    Paint paint,
  ) {
    if (polygon.isDotted) {
      final borderRadius = polygon.borderStrokeWidth / 2;
      final spacing = polygon.borderStrokeWidth * 1.5;
      for (final offsets in holeOffsetsList) {
        _addDottedLineToPath(
            canvas, paint, offsets, borderRadius, spacing, canvasSize);
      }
    } else {
      for (final offsets in holeOffsetsList) {
        _addLineToPath(path, offsets);
      }
    }
  }

  // Function to clip a line segment to a rectangular area (canvas)
  List<Offset>? _getVisibleSegment(Offset p0, Offset p1, Size canvasSize) {
    // Function to compute the outCode for a point relative to the canvas
    int computeOutCode(
      double x,
      double y,
      double xMin,
      double yMin,
      double xMax,
      double yMax,
    ) {
      int code = _csInside;

      if (x < xMin) {
        code |= _csLeft;
      } else if (x > xMax) {
        code |= _csRight;
      }
      if (y < yMin) {
        code |= _csBottom;
      } else if (y > yMax) {
        code |= _csTop;
      }

      return code;
    }

    const double xMin = 0;
    const double yMin = 0;
    final double xMax = canvasSize.width;
    final double yMax = canvasSize.height;

    double x0 = p0.dx;
    double y0 = p0.dy;
    double x1 = p1.dx;
    double y1 = p1.dy;

    int outCode0 = computeOutCode(x0, y0, xMin, yMin, xMax, yMax);
    int outCode1 = computeOutCode(x1, y1, xMin, yMin, xMax, yMax);
    bool accept = false;

    while (true) {
      if ((outCode0 | outCode1) == 0) {
        // Both points inside; trivially accept
        accept = true;
        break;
      } else if ((outCode0 & outCode1) != 0) {
        // Both points share an outside zone; trivially reject
        break;
      } else {
        // Could be partially inside; calculate intersection
        double x;
        double y;
        final int outCodeOut = outCode0 != 0 ? outCode0 : outCode1;

        if ((outCodeOut & _csTop) != 0) {
          x = x0 + (x1 - x0) * (yMax - y0) / (y1 - y0);
          y = yMax;
        } else if ((outCodeOut & _csBottom) != 0) {
          x = x0 + (x1 - x0) * (yMin - y0) / (y1 - y0);
          y = yMin;
        } else if ((outCodeOut & _csRight) != 0) {
          y = y0 + (y1 - y0) * (xMax - x0) / (x1 - x0);
          x = xMax;
        } else if ((outCodeOut & _csLeft) != 0) {
          y = y0 + (y1 - y0) * (xMin - x0) / (x1 - x0);
          x = xMin;
        } else {
          // This else block should never be reached.
          break;
        }

        // Update the point and outCode
        if (outCodeOut == outCode0) {
          x0 = x;
          y0 = y;
          outCode0 = computeOutCode(x0, y0, xMin, yMin, xMax, yMax);
        } else {
          x1 = x;
          y1 = y;
          outCode1 = computeOutCode(x1, y1, xMin, yMin, xMax, yMax);
        }
      }
    }

    if (accept) {
      // Make sure we return the points within the canvas
      return [Offset(x0, y0), Offset(x1, y1)];
    }
    return null;
  }

  void _addDottedLineToPath(
    Canvas canvas,
    Paint paint,
    List<Offset> offsets,
    double radius,
    double stepLength,
    Size canvasSize,
  ) {
    if (offsets.isEmpty) {
      return;
    }

    // Calculate for all segments, including closing the loop from the last to the first point
    final int totalOffsets = offsets.length;
    for (int i = 0; i < totalOffsets; i++) {
      final Offset start = offsets[i % totalOffsets];
      final Offset end =
          offsets[(i + 1) % totalOffsets]; // Wrap around to the first point

      // Attempt to adjust the segment to the visible part of the canvas
      final List<Offset>? visibleSegment =
          _getVisibleSegment(start, end, canvasSize);
      if (visibleSegment == null) {
        continue; // Skip if the segment is completely outside
      }

      final Offset adjustedStart = visibleSegment[0];
      final Offset adjustedEnd = visibleSegment[1];
      final double lineLength = (adjustedStart - adjustedEnd).distance;
      final Offset stepVector =
          (adjustedEnd - adjustedStart) / lineLength * stepLength;
      double traveledDistance = 0;

      Offset currentPoint = adjustedStart;
      while (traveledDistance < lineLength) {
        // Draw the circle if within the canvas bounds (additional check now redundant)
        canvas.drawCircle(currentPoint, radius, paint);

        // Move to the next point
        currentPoint = currentPoint + stepVector;
        traveledDistance += stepLength;
      }
    }
  }

  void _addLineToPath(Path path, List<Offset> offsets) {
    path.addPolygon(offsets, true);
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
