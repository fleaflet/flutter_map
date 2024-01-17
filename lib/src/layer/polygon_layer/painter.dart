part of 'polygon_layer.dart';

class _PolygonPainter extends CustomPainter {
  final List<_ProjectedPolygon> polygons;
  final MapCamera camera;
  final LatLngBounds bounds;
  final bool polygonLabels;
  final bool drawLabelsLast;

  _PolygonPainter({
    required this.polygons,
    required this.camera,
    required this.polygonLabels,
    required this.drawLabelsLast,
  }) : bounds = camera.visibleBounds;

  ({Offset min, Offset max}) getBounds(Offset origin, Polygon polygon) {
    final bbox = polygon.boundingBox;
    return (
      min: getOffset(camera, origin, bbox.southWest),
      max: getOffset(camera, origin, bbox.northEast),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    var filledPath = ui.Path();
    var borderPath = ui.Path();
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

          canvas.drawPath(filledPath, paint);
        }
      }

      // Draw polygon outline
      if (polygon.borderStrokeWidth > 0) {
        final borderPaint = _getBorderPaint(polygon);
        canvas.drawPath(borderPath, borderPaint);
      }

      filledPath = ui.Path();
      borderPath = ui.Path();
      lastPolygon = null;
      lastHash = null;
    }

    final origin = (camera.project(camera.center) - camera.size / 2).toOffset();

    // Main loop constructing batched fill and border paths from given polygons.
    for (final projectedPolygon in polygons) {
      if (projectedPolygon.points.isEmpty) {
        continue;
      }
      final polygon = projectedPolygon.polygon;
      final offsets = getOffsetsXY(camera, origin, projectedPolygon.points);

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
          filledPath.addPolygon(offsets, true);
        }
      }
      if (polygon.borderStrokeWidth > 0.0) {
        _addBorderToPath(borderPath, polygon, offsets);
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
          _addHoleBordersToPath(borderPath, polygon, holeOffsetsList);
        }
      }

      if (!drawLabelsLast && polygonLabels && polygon.textPainter != null) {
        // Labels are expensive because:
        //  * they themselves cannot easily be pulled into our batched path
        //    painting with the given text APIs
        //  * therefore, they require us to flush the batch of polygon draws to
        //    ensure polygons and labels are stacked correctly, i.e.:
        //    p1, p1_label, p2, p2_label, ... .

        // The painter will be null if the layouting algorithm determined that
        // there isn't enough space.
        final painter = _buildLabelTextPainter(
          mapSize: camera.size,
          placementPoint: camera.getOffsetFromOrigin(polygon.labelPosition),
          bounds: getBounds(origin, polygon),
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
            placementPoint:
                camera.project(polygon.labelPosition).toOffset() - origin,
            bounds: getBounds(origin, polygon),
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
    ui.Path path,
    Polygon polygon,
    List<Offset> offsets,
  ) {
    if (polygon.isDotted) {
      final borderRadius = polygon.borderStrokeWidth / 2;
      final spacing = polygon.borderStrokeWidth * 1.5;
      _addDottedLineToPath(path, offsets, borderRadius, spacing);
    } else {
      _addLineToPath(path, offsets);
    }
  }

  void _addHoleBordersToPath(
    ui.Path path,
    Polygon polygon,
    List<List<Offset>> holeOffsetsList,
  ) {
    if (polygon.isDotted) {
      final borderRadius = polygon.borderStrokeWidth / 2;
      final spacing = polygon.borderStrokeWidth * 1.5;
      for (final offsets in holeOffsetsList) {
        _addDottedLineToPath(path, offsets, borderRadius, spacing);
      }
    } else {
      for (final offsets in holeOffsetsList) {
        _addLineToPath(path, offsets);
      }
    }
  }

  void _addDottedLineToPath(
    ui.Path path,
    List<Offset> offsets,
    double radius,
    double stepLength,
  ) {
    if (offsets.isEmpty) {
      return;
    }

    double startDistance = 0;
    for (int i = 0; i < offsets.length; i++) {
      final o0 = offsets[i % offsets.length];
      final o1 = offsets[(i + 1) % offsets.length];
      final totalDistance = (o0 - o1).distance;

      double distance = startDistance;
      while (distance < totalDistance) {
        final done = distance / totalDistance;
        final remain = 1.0 - done;
        final offset = Offset(
          o0.dx * remain + o1.dx * done,
          o0.dy * remain + o1.dy * done,
        );
        path.addOval(Rect.fromCircle(center: offset, radius: radius));

        distance += stepLength;
      }

      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }

    path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
  }

  void _addLineToPath(ui.Path path, List<Offset> offsets) {
    path.addPolygon(offsets, true);
  }

  @override
  bool shouldRepaint(_PolygonPainter oldDelegate) => false;
}
