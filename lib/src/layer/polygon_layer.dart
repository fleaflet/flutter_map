import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/layer/label.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI

enum PolygonLabelPlacement {
  centroid,
  polylabel,
}

bool isClockwise(List<LatLng> points) {
  double sum = 0;
  for (int i = 0; i < points.length; ++i) {
    final a = points[i];
    final b = points[(i + 1) % points.length];

    sum += (b.longitude - a.longitude) * (b.latitude + a.latitude);
  }
  return sum >= 0;
}

class Polygon {
  final List<LatLng> points;
  final List<List<LatLng>>? holePointsList;

  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool disableHolesBorder;
  final bool isDotted;
  final bool isFilled;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final String? label;
  final TextStyle labelStyle;
  final PolygonLabelPlacement labelPlacement;
  final bool rotateLabel;
  // Designates whether the given polygon points follow a clock or anti-clockwise direction.
  // This is respected during draw call batching for filled polygons. Otherwise, batched polygons
  // of opposing clock-directions cut holes into each other leading to a leaky optimization.
  final bool _filledAndClockwise;

  LatLngBounds? _boundingBox;

  LatLngBounds get boundingBox =>
      _boundingBox ??= LatLngBounds.fromPoints(points);

  Polygon({
    required this.points,
    this.holePointsList,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.disableHolesBorder = false,
    this.isDotted = false,
    this.isFilled = false,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    this.labelPlacement = PolygonLabelPlacement.centroid,
    this.rotateLabel = false,
  }) : _filledAndClockwise = isFilled && isClockwise(points);

  /// Used to batch draw calls to the canvas.
  int get renderHashCode {
    _hash ??= Object.hash(
      holePointsList,
      color,
      borderStrokeWidth,
      borderColor,
      isDotted,
      isFilled,
      strokeCap,
      strokeJoin,
      _filledAndClockwise,
    );
    return _hash!;
  }

  int? _hash;
}

@immutable
class PolygonLayer extends StatelessWidget {
  final List<Polygon> polygons;

  /// screen space culling of polygons based on bounding box
  final bool polygonCulling;

  // Turn on/off per-polygon label drawing on the layer-level.
  final bool polygonLabels;

  const PolygonLayer({
    super.key,
    this.polygons = const [],
    this.polygonCulling = false,
    this.polygonLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    final size = Size(map.size.x, map.size.y);

    final pgons = polygonCulling
        ? polygons.where((p) {
            return p.boundingBox.isOverlapping(map.visibleBounds);
          }).toList()
        : polygons;

    return CustomPaint(
      painter: PolygonPainter(pgons, map, polygonLabels),
      size: size,
      isComplex: true,
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Polygon> polygons;
  final MapCamera map;
  final LatLngBounds bounds;
  final bool polygonLabels;

  PolygonPainter(this.polygons, this.map, this.polygonLabels)
      : bounds = map.visibleBounds;

  int get hash {
    _hash ??= Object.hashAll(polygons);
    return _hash!;
  }

  int? _hash;

  List<Offset> getOffsets(List<LatLng> points) {
    return List.generate(
      points.length,
      (index) {
        return map.getOffsetFromOrigin(points[index]);
      },
      growable: false,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    var filledPath = ui.Path();
    var borderPath = ui.Path();
    Polygon? lastPolygon;
    int? lastHash;

    // This functions flushes the batched fill and border paths constructed below.
    void drawPaths() {
      if (lastPolygon == null) {
        return;
      }
      final polygon = lastPolygon!;

      // Draw filled polygon .
      if (polygon.isFilled) {
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = polygon.color;

        canvas.drawPath(filledPath, paint);
      }

      // Draw polygon outline.
      if (polygon.borderStrokeWidth > 0) {
        final borderPaint = _getBorderPaint(polygon);
        canvas.drawPath(borderPath, borderPaint);
      }

      filledPath = ui.Path();
      borderPath = ui.Path();
      lastPolygon = null;
      lastHash = null;
    }

    // Main loop constructing batched fill and border paths from given polygons.
    for (final polygon in polygons) {
      final offsets = getOffsets(polygon.points);
      if (offsets.isEmpty) {
        continue;
      }

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
      if (polygon.isFilled) {
        filledPath.addPolygon(offsets, true);
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
          (i) => getOffsets(holePointsList[i]),
          growable: false,
        );

        for (final holeOffsets in holeOffsetsList) {
          filledPath.addPolygon(holeOffsets, true);
        }

        if (!polygon.disableHolesBorder && polygon.borderStrokeWidth > 0.0) {
          _addHoleBordersToPath(borderPath, polygon, holeOffsetsList);
        }
      }

      if (polygonLabels && polygon.label != null) {
        // Labels are expensive because:
        //  * they themselves cannot easily be pulled into our batched path
        //    painting with the given text APIs
        //  * therefore, they require us to flush the batch of polygon draws to
        //    ensure polygons and labels are stacked correctly, i.e.:
        //    p1, p1_label, p2, p2_label, ... .

        // The painter will be null if the layouting algorithm determined that
        // there isn't enough space.
        final painter = buildLabelTextPainter(
          points: offsets,
          labelText: polygon.label!,
          labelStyle: polygon.labelStyle,
          rotationRad: map.rotationRad,
          rotate: polygon.rotateLabel,
          labelPlacement: polygon.labelPlacement,
          padding: 10,
        );

        if (painter != null) {
          // Flush the batch before painting to preserve stacking.
          drawPaths();

          painter(canvas);
        }
      }
    }

    drawPaths();
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
      ui.Path path, List<Offset> offsets, double radius, double stepLength) {
    if (offsets.isEmpty) {
      return;
    }

    double startDistance = 0;
    for (var i = 0; i < offsets.length; i++) {
      final o0 = offsets[i % offsets.length];
      final o1 = offsets[(i + 1) % offsets.length];
      final totalDistance = (o0 - o1).distance;

      double distance = startDistance;
      for (; distance < totalDistance; distance += stepLength) {
        final done = distance / totalDistance;
        final remain = 1.0 - done;
        final offset = Offset(
          o0.dx * remain + o1.dx * done,
          o0.dy * remain + o1.dy * done,
        );
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
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
  bool shouldRepaint(PolygonPainter oldDelegate) {
    return oldDelegate.bounds != bounds ||
        oldDelegate.polygons.length != polygons.length ||
        oldDelegate.hash != hash;
  }
}
