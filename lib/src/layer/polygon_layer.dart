import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/label.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI
import 'package:flutter/foundation.dart' show kIsWeb;

enum PolygonLabelPlacement {
  centroid,
  polylabel,
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

  LatLngBounds? _boundingBox;
  LatLngBounds get boundingBox {
    _boundingBox ??= LatLngBounds.fromPoints(points);
    return _boundingBox!;
  }

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
  });

  /// Used to batch draw calls to the canvas.
  int get renderHashCode => Object.hash(
      holePointsList?.length ?? 0,
      color,
      borderStrokeWidth,
      borderColor,
      isDotted,
      isFilled,
      strokeCap,
      strokeJoin,
      labelStyle);
}

class PolygonLayer extends StatelessWidget {
  final List<Polygon> polygons;

  /// screen space culling of polygons based on bounding box
  final bool polygonCulling;

  const PolygonLayer({
    super.key,
    this.polygons = const [],
    this.polygonCulling = false,
  });

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;
    final size = Size(map.size.x, map.size.y);
    final origin = map.pixelOrigin;
    final offset = Offset(origin.x.toDouble(), origin.y.toDouble());

    final Iterable<Polygon> pgons = polygonCulling
        ? polygons.where((p) {
            return p.boundingBox.isOverlapping(map.bounds);
          })
        : polygons;

    final paint = CustomPaint(
      painter: PolygonPainter(pgons, map),
      size: size,
      willChange: false,
      isComplex: true,
    );
    return Positioned(
      left: -offset.dx,
      top: -offset.dy,
      child: kIsWeb ? paint : RepaintBoundary(child: paint),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Iterable<Polygon> polygons;
  final FlutterMapState map;
  final double zoom;
  final double rotation;

  PolygonPainter(this.polygons, this.map)
      : zoom = map.zoom,
        rotation = map.rotation;

  int get hash {
    _hash ??= Object.hashAll(polygons);
    return _hash!;
  }

  int? _hash;

  List<Offset> getOffsets(List<LatLng> points) {
    return points.map((pos) => getOffset(pos)).toList();
  }

  Offset getOffset(LatLng point) {
    final delta = map.project(point);
    return Offset(delta.x.toDouble(), delta.y.toDouble());
  }

  @override
  void paint(Canvas canvas, Size size) {
    var path = ui.Path();
    var paint = Paint();
    var borderPath = ui.Path();
    Paint? borderPaint;
    int? lastHash;

    void drawPaths() {
      canvas.drawPath(path, paint);
      path = ui.Path();
      paint = Paint();

      if (borderPaint != null) {
        canvas.drawPath(borderPath, borderPaint!);
        borderPath = ui.Path();
        borderPaint = null;
      }
    }

    for (final polygon in polygons) {
      final offsets = getOffsets(polygon.points);
      if (offsets.isEmpty) {
        continue;
      }

      final hash = polygon.renderHashCode;
      if (lastHash != null && lastHash != hash) {
        drawPaths();
      }
      lastHash = hash;

      final holeOffsetsList = List<List<Offset>>.generate(
          polygon.holePointsList?.length ?? 0,
          (i) => getOffsets(polygon.holePointsList![i]));

      if (holeOffsetsList.isEmpty) {
        if (polygon.isFilled) {
          paint = Paint()
            ..style = PaintingStyle.fill
            ..strokeWidth = polygon.borderStrokeWidth
            ..strokeCap = polygon.strokeCap
            ..strokeJoin = polygon.strokeJoin
            ..color = polygon.isFilled ? polygon.color : polygon.borderColor;

          path.addPolygon(offsets, true);
        }
      } else {
        paint = Paint()
          ..style = PaintingStyle.fill
          ..color = polygon.color;

        // Ideally we'd use `Path.combine(PathOperation.difference, ...)`
        // instead of evenOdd fill-type, however it creates visual artifacts
        // using the web renderer.
        path.fillType = PathFillType.evenOdd;

        path.addPolygon(offsets, true);
        for (final holeOffsets in holeOffsetsList) {
          path.addPolygon(holeOffsets, true);
        }
      }

      // Only draw the  border explicitly if it isn't alrady a stroke-style
      // polygon.
      if (polygon.borderStrokeWidth > 0.0) {
        borderPaint = _getBorderPaint(polygon);
        _paintBorder(borderPath, polygon, offsets, holeOffsetsList);
      }

      if (polygon.label != null) {
        // Labels are expensive they mess with draw batching.
        drawPaths();

        Label.paintText(
          canvas,
          offsets,
          polygon.label,
          polygon.labelStyle,
          map.rotationRad,
          rotate: polygon.rotateLabel,
          labelPlacement: polygon.labelPlacement,
        );
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

  void _paintBorder(ui.Path path, Polygon polygon, List<Offset> offsets,
      List<List<Offset>> holeOffsetsList) {
    if (polygon.isDotted) {
      final borderRadius = (polygon.borderStrokeWidth / 2);
      final spacing = polygon.borderStrokeWidth * 1.5;

      _paintDottedLine(path, offsets, borderRadius, spacing);

      if (!polygon.disableHolesBorder) {
        for (final offsets in holeOffsetsList) {
          _paintDottedLine(path, offsets, borderRadius, spacing);
        }
      }
    } else {
      _paintLine(path, offsets);

      if (!polygon.disableHolesBorder) {
        for (final offsets in holeOffsetsList) {
          _paintLine(path, offsets);
        }
      }
    }
  }

  void _paintDottedLine(
      ui.Path path, List<Offset> offsets, double radius, double stepLength) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length; i++) {
      final o0 = offsets[i % offsets.length];
      final o1 = offsets[(i + 1) % offsets.length];
      final totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        final f1 = distance / totalDistance;
        final f0 = 1.0 - f1;
        final offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
  }

  void _paintLine(ui.Path path, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return;
    }
    path.addPolygon(offsets, true);
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) {
    return kIsWeb ||
        oldDelegate.zoom != zoom ||
        oldDelegate.rotation != rotation ||
        oldDelegate.hash != hash;
  }
}

double _dist(Offset v, Offset w) {
  return sqrt(_sqr(v.dx - w.dx) + _sqr(v.dy - w.dy));
}

double _sqr(double x) {
  return x * x;
}
